import assert from "assert";
import * as crypto from "crypto";
// import * as ethers from "ethers";
const {
  buildBabyjub,
  buildMimc7,
  buildEddsa,
  buildPoseidon,
} = require("circomlibjs");

const createBlakeHash = require("blake-hash");

const ff = require("ffjavascript");

export type PrivKey = bigint;
export type PubKey = Uint8Array[];
export type EcdhSharedKey = Uint8Array;
export type Plaintext = bigint[];

export interface Keypair {
  privKey: PrivKey;
  pubKey: PubKey;
}

export interface Ciphertext {
  // The initialisation vector
  iv: bigint;

  // The encrypted data
  data: bigint[];
}

// An EdDSA signature.
export interface Signature {
  R8: BigInt[];
  S: BigInt;
}

export interface EdDSA {
  prv2pub: (prv: string) => Uint8Array[];
  pruneBuffer: () => Uint8Array;
  signPoseidon: (privKey: PrivKey, msg: bigint[]) => Signature;
  verifyPoseidon: (
    msg: bigint[],
    signature: Signature,
    pubKey: PubKey
  ) => boolean;
}

export const SNARK_FIELD_SIZE = BigInt(
  "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

/*
 * Convert a BigInt to a Buffer
 */
export const bigInt2Buffer = (i: BigInt): Buffer => {
  let hexStr = i.toString(16);
  while (hexStr.length < 64) {
    hexStr = "0" + hexStr;
  }
  return Buffer.from(hexStr, "hex");
};

/**
 * A TypedArray object describes an array-like view of an underlying binary data buffer.
 */
export type TypedArray =
  | Int8Array
  | Uint8Array
  | Uint8ClampedArray
  | Int16Array
  | Uint16Array
  | Int32Array
  | Uint32Array
  | Float32Array
  | Float64Array
  | BigInt64Array
  | BigUint64Array;

/**
 * Convert TypedArray object(like data buffer) into bigint
 */
export const buf2Bigint = (buf: ArrayBuffer | TypedArray | Buffer): bigint => {
  let bits = 8n;
  if (ArrayBuffer.isView(buf)) bits = BigInt(buf.BYTES_PER_ELEMENT * 8);
  else buf = new Uint8Array(buf);

  let ret = 0n;
  for (const i of (buf as TypedArray | Buffer).values()) {
    const bi = BigInt(i);
    ret = (ret << bits) + bi;
  }
  return ret;
};

export const sha512hex = (secret: string): string => {
  return `0x${crypto.createHash("sha512").update(secret).digest("hex")}`;
};

export const buildEddsaModule = async (): Promise<EdDSA> => {
  return buildEddsa();
};

const genPrivKey = async (
  username: string,
  password: string
): Promise<PrivKey> => {
  const poseidon = await buildPoseidon();

  const usernameHash = poseidon([sha512hex(username)]);

  const passwordHash = poseidon([sha512hex(password)]);

  return poseidon([usernameHash, passwordHash]);
};

const formatPrivKey = (eddsa: any, privKey: PrivKey) => {
  const sBuff = eddsa.pruneBuffer(
    createBlakeHash("blake512")
      .update(Buffer.from(privKey.toString()))
      .digest()
      .slice(0, 32)
  );
  const s = ff.utils.leBuff2int(sBuff);
  return ff.Scalar.shr(s, 3);
};

// const packPubKey = async (pubKey: PubKey): Promise<Buffer> => {
//   const babyJub = await buildBabyjub();
//   return babyJub.packPoint(pubKey);
// };

// const unpackPubKey = async (packed: Buffer): Promise<PubKey> => {
//   const babyJub = await buildBabyjub();
//   return babyJub.unpackPoint(packed);
// };

const genPubKey = (eddsa: EdDSA, privKey: PrivKey): Uint8Array[] => {
  assert(privKey < SNARK_FIELD_SIZE);
  return eddsa.prv2pub(privKey.toString());
};

export const genKeypair = async (
  eddsa: EdDSA,
  username: string,
  password: string
): Promise<Keypair> => {
  const privKey = await genPrivKey(username, password);
  const pubKey = genPubKey(eddsa, privKey);

  const Keypair: Keypair = { privKey, pubKey };

  return Keypair;
};

/*
 * Generates an Elliptic-curve Diffie–Hellman shared key given a private key
 * and a public key.
 */
export const genEcdhSharedKey = async ({
  eddsa,
  privKey,
  pubKey,
}: {
  eddsa: EdDSA;
  privKey: PrivKey;
  pubKey: PubKey;
}): Promise<EcdhSharedKey> => {
  const babyJub = await buildBabyjub();
  return babyJub.mulPointEscalar(pubKey, formatPrivKey(eddsa, privKey))[0];
};

/*
 * Encrypts a plaintext using a given key.
 */
export const encrypt = async (
  plaintext: Plaintext,
  sharedKey: EcdhSharedKey
): Promise<Ciphertext> => {
  const mimc7 = await buildMimc7();

  const iv = mimc7.getIV();

  const ciphertext: Ciphertext = {
    iv,
    data: plaintext.map((e: bigint, i: number): bigint => {
      return e + buf2Bigint(mimc7.hash(sharedKey, iv + BigInt(i)));
    }),
  };

  return ciphertext;
};

/*
 * Decrypts a ciphertext using a given key.
 * @return The plaintext.
 */
export const decrypt = async (
  ciphertext: Ciphertext,
  sharedKey: EcdhSharedKey
): Promise<Plaintext> => {
  const mimc7 = await buildMimc7();

  const plaintext: Plaintext = ciphertext.data.map(
    (e: bigint, i: number): bigint => {
      return e - buf2Bigint(mimc7.hash(sharedKey, ciphertext.iv + BigInt(i)));
    }
  );

  return plaintext;
};

// export {
//   buildEddsaModule,
//   buf2Bigint,
//   genPrivKey,
//   genPubKey,
//   genKeypair,
//   genEcdhSharedKey,
//   encrypt,
//   decrypt,
//   Signature,
//   PrivKey,
//   PubKey,
//   Keypair,
//   EcdhSharedKey,
//   EdDSA,
//   Ciphertext,
//   Plaintext,
//   TypedArray,
//   //   formatPrivKeyForBabyJub,
//   //   NOTHING_UP_MY_SLEEVE,
//   //   NOTHING_UP_MY_SLEEVE_PUBKEY,
//   SNARK_FIELD_SIZE,
//   bigInt2Buffer,
//   //   packPubKey,
//   //   unpackPubKey,
// };
