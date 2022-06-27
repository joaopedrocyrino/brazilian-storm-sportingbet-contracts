const { groth16 } = require("snarkjs");

export const unstringifyBigInts = (
  o: string | any[] | { [k: string]: any }
): any => {
  if (o) {
    if (
      typeof o === "string" &&
      (/^[0-9]+$/.test(o) || /^0x[0-9a-fA-F]+$/.test(o))
    ) {
      return BigInt(o);
    } else if (Array.isArray(o)) {
      return o.map(unstringifyBigInts);
    } else if (typeof o === "object") {
      const res: { [k: string]: any } = {};
      const keys = Object.keys(o);
      keys.forEach((k) => {
        res[k] = unstringifyBigInts(o[k]);
      });
      return res;
    } else {
      return o;
    }
  } else {
    return null;
  }
};

export const grothProof = async (
  Input: { [k: string]: any },
  wasm: string,
  zkey: string
) => {
  const { proof, publicSignals } = await groth16.fullProve(Input, wasm, zkey);

  const editedPublicSignals = unstringifyBigInts(publicSignals);
  const editedProof = unstringifyBigInts(proof);
  const calldata = await groth16.exportSolidityCallData(
    editedProof,
    editedPublicSignals
  );

  const argv = calldata
    .replace(/["[\]\s]/g, "")
    .split(",")
    .map((x: any) => BigInt(x).toString());

  const a = [argv[0], argv[1]];
  const b = [
    [argv[2], argv[3]],
    [argv[4], argv[5]],
  ];
  const c = [argv[6], argv[7]];
  const input = argv.slice(8);

  return { a, b, c, input };
};

export const decrypt = async (
  ciphertext: bigint,
  secret: bigint
): Promise<bigint> => {
  const { publicSignals } = await groth16.fullProve(
    { ciphertext, secret },
    "circuits/Decrypt/decrypt_js/decrypt.wasm",
    "circuits/Decrypt/circuit_final.zkey"
  );

  const editedPublicSignals = unstringifyBigInts(publicSignals);

  return editedPublicSignals;
};
