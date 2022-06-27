import assert from "assert";
import {
  Keypair,
  EdDSA,
  genKeypair,
  sha512hex,
  poseidonHash,
  Fr,
  genEcdhSharedKey,
} from "../utils/encryption";

const { buildEddsa } = require("circomlibjs");

const wasmTester = require("circom_tester").wasm;

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
