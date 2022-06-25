// import { ethers } from "hardhat";
// import { expect } from "chai";
// import { Contract } from "ethers";
// const { groth16 } = require("snarkjs");

// const unstringifyBigInts = (o: string | any[] | { [k: string]: any }): any => {
//   if (o) {
//     if (
//       typeof o === "string" &&
//       (/^[0-9]+$/.test(o) || /^0x[0-9a-fA-F]+$/.test(o))
//     ) {
//       return BigInt(o);
//     } else if (Array.isArray(o)) {
//       return o.map(unstringifyBigInts);
//     } else if (typeof o === "object") {
//       const res: { [k: string]: any } = {};
//       const keys = Object.keys(o);
//       keys.forEach((k) => {
//         res[k] = unstringifyBigInts(o[k]);
//       });
//       return res;
//     } else {
//       return o;
//     }
//   } else {
//     return null;
//   }
// };

// const grothProof = async (
//   Input: { [k: string]: any },
//   wasm: string,
//   zkey: string
// ): Promise<{ a: any[]; b: any[][]; c: any[]; input: any }> => {
//   const { proof, publicSignals } = await groth16.fullProve(Input, wasm, zkey);

//   console.log("\n my pub signals are: ", publicSignals, "\n");

//   const editedPublicSignals = unstringifyBigInts(publicSignals);
//   const editedProof = unstringifyBigInts(proof);
//   const calldata = await groth16.exportSolidityCallData(
//     editedProof,
//     editedPublicSignals
//   );

//   const argv = calldata
//     .replace(/["[\]\s]/g, "")
//     .split(",")
//     .map((x: any) => BigInt(x).toString());

//   const a = [argv[0], argv[1]];
//   const b = [
//     [argv[2], argv[3]],
//     [argv[4], argv[5]],
//   ];
//   const c = [argv[6], argv[7]];
//   const input = argv.slice(8);

//   return { a, b, c, input };
// };

// describe("Deposit", () => {
//   let deposit: Contract;

//   before(async () => {});

//   beforeEach(async () => {});
// });
