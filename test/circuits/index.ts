import assert from "assert";
import * as crypto from "crypto";
const { buildBabyjub, buildEddsa, buildPoseidon } = require("circomlibjs");

const createBlakeHash = require("blake-hash");
const ff = require("ffjavascript");
const wasmTester = require("circom_tester").wasm;
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;

const SNARK_FIELD_SIZE = BigInt(
  "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);
exports.p = Scalar.fromString(SNARK_FIELD_SIZE.toString());

const Fr = new F1Field(exports.p);

type PrivKey = bigint;
type PubKey = Uint8Array[];
type EcdhSharedKey = bigint;

interface Keypair {
  privKey: PrivKey;
  pubKey: PubKey;
}

// An EdDSA signature.
interface Signature {
  R8: BigInt[];
  S: BigInt;
}

interface EdDSA {
  prv2pub: (prv: string) => Uint8Array[];
  pruneBuffer: () => Uint8Array;
  signPoseidon: (privKey: PrivKey, msg: bigint[]) => Signature;
  verifyPoseidon: (
    msg: bigint[],
    signature: Signature,
    pubKey: PubKey
  ) => boolean;
}

/**
 * A TypedArray object describes an array-like view of an underlying binary data buffer.
 */
type TypedArray =
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
const buf2Bigint = (buf: ArrayBuffer | TypedArray | Buffer): bigint => {
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

const poseidonHash = async (elements: any[]) => {
  const poseidon = await buildPoseidon();
  const F = poseidon.F;

  return F.toObject(poseidon(elements));
};

const sha512hex = async (secret: string): Promise<bigint> => {
  return await poseidonHash([
    `0x${crypto.createHash("sha512").update(secret).digest("hex")}`,
  ]);
};

const genPrivKey = async (
  username: string,
  password: string
): Promise<PrivKey> => {
  const usernameHash = await sha512hex(username);

  const passwordHash = await sha512hex(password);

  return await poseidonHash([usernameHash, passwordHash]);
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

const genPubKey = (eddsa: EdDSA, privKey: PrivKey): Uint8Array[] => {
  assert(privKey < SNARK_FIELD_SIZE);
  return eddsa.prv2pub(privKey.toString());
};

const genKeypair = async (
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
const genEcdhSharedKey = async ({
  eddsa,
  privKey,
  pubKey,
}: {
  eddsa: EdDSA;
  privKey: PrivKey;
  pubKey: PubKey;
}): Promise<EcdhSharedKey> => {
  const babyJub = await buildBabyjub();

  return buf2Bigint(
    babyJub.mulPointEscalar(pubKey, formatPrivKey(eddsa, privKey))[0]
  );
};

describe("\n-----CIRCUITS-----\n", () => {
  let decrypt: any, keyPair: Keypair, eddsa: EdDSA;

  before(async () => {
    eddsa = await buildEddsa();

    decrypt = await wasmTester("circuits/decrypt.circom");
    await decrypt.loadConstraints();

    keyPair = await genKeypair(
      eddsa,
      "MY SUPER SECRET USERNAME",
      "MY SUPER SECRET PASSWORD"
    );

    console.log("pub: ", keyPair.pubKey);
  });

  describe("\n 1) create user circom circuit \n", async () => {
    let username: bigint, password: bigint, witness: bigint[];

    before(async () => {
      const circuit = await wasmTester("circuits/createUser.circom");
      await circuit.loadConstraints();

      username = await sha512hex("MY SUPER SECRET USERNAME");
      password = await sha512hex("MY SUPER SECRET PASSWORD");

      const INPUT = {
        username,
        password,
      };

      witness = await circuit.calculateWitness(INPUT, true);
    });

    it("Should calc same identity commitment", async () => {
      const identityCommitment = await poseidonHash([keyPair.privKey]);

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(witness[1]), Fr.e(identityCommitment)));
    });

    it("Should calc same username commitment", async () => {
      const usernameCommitment = await poseidonHash([username]);

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(witness[2]), Fr.e(usernameCommitment)));
    });

    it("Should decrypt initial balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[3],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(0), Fr.e(decryptWitness[1])));
    });
  });

  describe("\n 2) deposit circom circuit \n", async () => {
    let witness: bigint[];

    before(async () => {
      const circuit = await wasmTester("circuits/deposit.circom");
      await circuit.loadConstraints();

      const INPUT = {
        identity: keyPair.privKey,
        currentBalance: 33,
        value: 11,
      };

      witness = await circuit.calculateWitness(INPUT, true);
    });

    it("Should calc same identity commitment", async () => {
      const identityCommitment = await poseidonHash([keyPair.privKey]);

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(witness[1]), Fr.e(identityCommitment)));
    });

    it("Should calc same decrypt current balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[2],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[1]), Fr.e(33)));
    });

    it("Should decrypt new balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[3],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(44), Fr.e(decryptWitness[1])));
    });
  });

  describe("\n 3) withdrawn circom circuit \n", async () => {
    let witness: bigint[];

    before(async () => {
      const circuit = await wasmTester("circuits/withdrawn.circom");
      await circuit.loadConstraints();

      const INPUT = {
        identity: keyPair.privKey,
        currentBalance: 33,
        value: 11,
      };

      witness = await circuit.calculateWitness(INPUT, true);
    });

    it("Should calc same identity commitment", async () => {
      const identityCommitment = await poseidonHash([keyPair.privKey]);

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(witness[1]), Fr.e(identityCommitment)));
    });

    it("Should calc same decrypt current balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[2],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[1]), Fr.e(33)));
    });

    it("Should decrypt new balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[3],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(22), Fr.e(decryptWitness[1])));
    });
  });

  describe("\n 4) claim bet circom circuit \n", async () => {
    let witness: bigint[], sharedSecret: bigint, secret: bigint;

    before(async () => {
      const circuit = await wasmTester("circuits/claimBetWin.circom");
      await circuit.loadConstraints();

      const coordinatorKeyPar = await genKeypair(
        eddsa,
        "SECRET COORDINATOR USERNAME",
        "SECRET COORDINATOR PASSWORD"
      );

      sharedSecret = await genEcdhSharedKey({
        eddsa,
        privKey: keyPair.privKey,
        pubKey: coordinatorKeyPar.pubKey,
      });

      secret = await genEcdhSharedKey({
        eddsa,
        privKey: coordinatorKeyPar.privKey,
        pubKey: keyPair.pubKey,
      });

      const INPUT = {
        identity: keyPair.privKey,
        currentBalance: 33,
        value: 11,
        sharedSecret,
        rate: 200,
      };

      witness = await circuit.calculateWitness(INPUT, true);
    });

    it("Should calc same identity commitment", async () => {
      const identityCommitment = await poseidonHash([keyPair.privKey]);

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(witness[1]), Fr.e(identityCommitment)));
    });

    it("Should calc same decrypt current balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[2],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[1]), Fr.e(33)));
    });

    it("Should decrypt new balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[3],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(55), Fr.e(decryptWitness[1])));
    });

    it("Should decrypt bet value", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[4],
          secret,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(11), Fr.e(decryptWitness[1])));
    });
  });

  describe("\n 5) make bet circom circuit \n", async () => {
    let witness: bigint[], sharedSecret: bigint, secret: bigint;

    before(async () => {
      const circuit = await wasmTester("circuits/makeBet.circom");
      await circuit.loadConstraints();

      const coordinatorKeyPar = await genKeypair(
        eddsa,
        "SECRET COORDINATOR USERNAME",
        "SECRET COORDINATOR PASSWORD"
      );

      sharedSecret = await genEcdhSharedKey({
        eddsa,
        privKey: keyPair.privKey,
        pubKey: coordinatorKeyPar.pubKey,
      });

      secret = await genEcdhSharedKey({
        eddsa,
        privKey: coordinatorKeyPar.privKey,
        pubKey: keyPair.pubKey,
      });

      const INPUT = {
        identity: keyPair.privKey,
        currentBalance: 33,
        value: 11,
        sharedSecret,
      };

      witness = await circuit.calculateWitness(INPUT, true);
    });

    it("Should calc same identity commitment", async () => {
      const identityCommitment = await poseidonHash([keyPair.privKey]);

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(witness[1]), Fr.e(identityCommitment)));
    });

    it("Should calc same decrypt current balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[2],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[1]), Fr.e(33)));
    });

    it("Should decrypt new balance", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[3],
          secret: keyPair.privKey,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(22), Fr.e(decryptWitness[1])));
    });

    it("Should decrypt bet value", async () => {
      const decryptWitness: bigint[] = await decrypt.calculateWitness(
        {
          ciphertext: witness[4],
          secret,
        },
        true
      );

      assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(decryptWitness[0]), Fr.e(1)));
      assert(Fr.eq(Fr.e(11), Fr.e(decryptWitness[1])));
    });
  });
});
