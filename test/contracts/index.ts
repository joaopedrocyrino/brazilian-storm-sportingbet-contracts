import assert from "assert";
import { ethers } from "hardhat";
import { expect } from "chai";

import {
  Keypair,
  EdDSA,
  genKeypair,
  sha512hex,
  poseidonHash,
  genEcdhSharedKey,
} from "../utils/encryption";
import { grothProof } from "../utils/groth";

const { buildEddsa } = require("circomlibjs");

const wasms = {
  createUser: "circuits/CreateUser/createUser_js/createUser.wasm",
  deposit: "circuits/DepositProof/deposit_js/deposit.wasm",
  withdrawn: "circuits/Withdrawn/withdrawn_js/withdrawn.wasm",
  decrypt: "circuits/Decrypt/decrypt_js/decrypt.wasm",
  makeBet: "circuits/MakeBet/makeBet_js/makeBet.wasm",
  claimBet: "circuits/ClaimBet/claimBetWin_js/claimBetWin.wasm",
};

const zkeys = {
  createUser: "circuits/CreateUser/circuit_final.zkey",
  deposit: "circuits/DepositProof/circuit_final.zkey",
  withdrawn: "circuits/Withdrawn/circuit_final.zkey",
  decrypt: "circuits/Decrypt/circuit_final.zkey",
  makeBet: "circuits/MakeBet/circuit_final.zkey",
  claimBet: "circuits/ClaimBet/circuit_final.zkey",
};

describe("\n--------CONTRACTS--------\n", () => {
  let keyPair: Keypair,
    coordinatorKeyPair: Keypair,
    eddsa: EdDSA,
    createUserContract: any,
    depositContract: any,
    withdrawnContract: any,
    betContract: any,
    claimBetContract: any,
    brazilianStormContract: any;

  before(async () => {
    eddsa = await buildEddsa();

    keyPair = await genKeypair(
      eddsa,
      "MY SUPER SECRET USERNAME",
      "MY SUPER SECRET PASSWORD"
    );

    coordinatorKeyPair = await genKeypair(
      eddsa,
      "MY SUPER SECRET COORDINATOR USERNAME",
      "MY SUPER SECRET COORDINATOR PASSWORD"
    );

    const CreateUserContract = await ethers.getContractFactory(
      "CreateUserVerifier"
    );

    createUserContract = await CreateUserContract.deploy();
    await createUserContract.deployed();

    const DepositContract = await ethers.getContractFactory("DepositVerifier");

    depositContract = await DepositContract.deploy();
    await depositContract.deployed();

    const WithdrawnContract = await ethers.getContractFactory(
      "WithdrawnVerifier"
    );

    withdrawnContract = await WithdrawnContract.deploy();
    await withdrawnContract.deployed();

    const MakeBetContract = await ethers.getContractFactory("MakeBetVerifier");

    betContract = await MakeBetContract.deploy();
    await betContract.deployed();

    const ClaimBetContract = await ethers.getContractFactory(
      "ClaimBetVerifier"
    );

    claimBetContract = await ClaimBetContract.deploy();
    await claimBetContract.deployed();

    const BrazilianStorm = await ethers.getContractFactory(
      "BrazilianStormSportingbet"
    );

    brazilianStormContract = await BrazilianStorm.deploy(
      createUserContract.address,
      depositContract.address,
      withdrawnContract.address,
      betContract.address,
      claimBetContract.address,
      [
        // @ts-ignore
        Array.from(coordinatorKeyPair.pubKey[0]),
        // @ts-ignore
        Array.from(coordinatorKeyPair.pubKey[1]),
      ]
    );
    await brazilianStormContract.deployed();
  });

  describe("\n 1) CREATE USER VERIFIER", () => {
    it("should pass valid info", async () => {
      const username = await sha512hex("MY SUPER SECRET USERNAME");
      const password = await sha512hex("MY SUPER SECRET PASSWORD");

      const { a, b, c, input } = await grothProof(
        { username, password },
        wasms.createUser,
        zkeys.createUser
      );

      const isValid = await createUserContract.verifyProof(a, b, c, input);

      assert(isValid);
    });
  });

  describe("\n 2) DEPOSIT VERIFIER", () => {
    it("should pass valid info", async () => {
      const { a, b, c, input } = await grothProof(
        {
          identity: keyPair.privKey,
          currentBalance: 0,
          value: BigInt("1000000000000000000"),
        },
        wasms.deposit,
        zkeys.deposit
      );

      const isValid = await depositContract.verifyProof(a, b, c, input);

      assert(isValid);
    });
  });

  describe("\n 3) WITHDRAWN VERIFIER", () => {
    it("should pass valid info", async () => {
      const { a, b, c, input } = await grothProof(
        {
          identity: keyPair.privKey,
          currentBalance: BigInt("2000000000000000000"),
          value: BigInt("1000000000000000000"),
        },
        wasms.withdrawn,
        zkeys.withdrawn
      );

      const isValid = await withdrawnContract.verifyProof(a, b, c, input);

      assert(isValid);
    });
  });

  describe("\n 6) BRAZILIAN STORM SPORTINGBET", () => {
    describe("\n------users-------\n", () => {
      let username: bigint, password: bigint;

      before(async () => {
        username = await sha512hex("MY SUPER SECRET USERNAME");
        password = await sha512hex("MY SUPER SECRET PASSWORD");
      });

      it("should create a user", async () => {
        const identityCommitment = await poseidonHash([keyPair.privKey]);

        let user = await brazilianStormContract.users(identityCommitment);

        assert(!user.isActive);
        assert(BigInt(user.balance) === 0n);

        const { a, b, c, input } = await grothProof(
          { username, password },
          wasms.createUser,
          zkeys.createUser
        );

        await brazilianStormContract.createUser(a, b, c, input, [
          Array.from(keyPair.pubKey[0]),
          Array.from(keyPair.pubKey[1]),
        ]);

        user = await brazilianStormContract.users(identityCommitment);

        const decryptProof = await grothProof(
          { ciphertext: BigInt(user.balance), secret: keyPair.privKey },
          wasms.decrypt,
          zkeys.decrypt
        );

        assert(user.isActive);
        assert(decryptProof.input[0] === "0");
      });

      it("should not create a user with taken username", async () => {
        const { a, b, c, input } = await grothProof(
          { username, password },
          wasms.createUser,
          zkeys.createUser
        );

        await expect(
          brazilianStormContract.createUser(a, b, c, input, [
            Array.from(keyPair.pubKey[0]),
            Array.from(keyPair.pubKey[1]),
          ])
        ).to.be.revertedWith("Username is taken");
      });
    });

    describe("\n------MATCHES--------\n", () => {
      it("should create match", async () => {
        const now = new Date().getTime();

        await brazilianStormContract.createMatch(33, 2022, "CAM", "FLA", now);

        const matchId = await brazilianStormContract._matchIds();

        const match = await brazilianStormContract.getMatch(
          BigInt(matchId) - 1n
        );

        assert(match[0] === 33);
        assert(match[1] === 2022);
        assert(match[2] === "CAM");
        assert(match[3] === "FLA");
        assert(BigInt(match[4]) === BigInt(now));
        assert(!match[5]);
      });
    });

    describe("\n------balance change-------\n", () => {
      let identityCommitment: bigint;

      before(async () => {
        identityCommitment = await poseidonHash([keyPair.privKey]);
      });

      it("should deposit", async () => {
        const { a, b, c, input } = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 0,
            value: 1000000000000000000n,
          },
          wasms.deposit,
          zkeys.deposit
        );

        await brazilianStormContract.deposit(a, b, c, input, {
          value: ethers.utils.parseUnits("1", "ether"),
        });

        const user = await brazilianStormContract.users(identityCommitment);

        const decryptProof = await grothProof(
          { ciphertext: BigInt(user.balance), secret: keyPair.privKey },
          wasms.decrypt,
          zkeys.decrypt
        );

        assert(user.isActive);
        assert(decryptProof.input[0] === "1000000000000000000");
      });

      it("should not deposit with wrong current balance", async () => {
        const { a, b, c, input } = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 0,
            value: 1000000000000000000n,
          },
          wasms.deposit,
          zkeys.deposit
        );

        await expect(
          brazilianStormContract.deposit(a, b, c, input, {
            value: ethers.utils.parseUnits("1", "ether"),
          })
        ).to.be.revertedWith("Invalid deposit");
      });

      it("should not deposit with wrong value", async () => {
        const { a, b, c, input } = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 1000000000000000000n,
            value: 2000000000000000000n,
          },
          wasms.deposit,
          zkeys.deposit
        );

        await expect(
          brazilianStormContract.deposit(a, b, c, input, {
            value: ethers.utils.parseUnits("1", "ether"),
          })
        ).to.be.revertedWith("Invalid deposit");
      });

      it("should withdrawn", async () => {
        const { a, b, c, input } = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 1000000000000000000n,
            value: 10000000000000000n,
          },
          wasms.withdrawn,
          zkeys.withdrawn
        );

        await brazilianStormContract.withdrawn(a, b, c, input);

        const user = await brazilianStormContract.users(identityCommitment);

        const decryptProof = await grothProof(
          { ciphertext: BigInt(user.balance), secret: keyPair.privKey },
          wasms.decrypt,
          zkeys.decrypt
        );

        assert(decryptProof.input[0] === "990000000000000000");
      });

      it("should not withdrawn with wrong current balance", async () => {
        const { a, b, c, input } = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 1000000000000000000n,
            value: 990000000000000000n,
          },
          wasms.withdrawn,
          zkeys.withdrawn
        );

        await expect(
          brazilianStormContract.withdrawn(a, b, c, input)
        ).to.be.revertedWith("Invalid withdrawn");
      });

      it("should not withdrawn with value bigger than balance", async () => {
        try {
          const { a, b, c, input } = await grothProof(
            {
              identity: keyPair.privKey,
              currentBalance: 990000000000000000n,
              value: 1000000000000000000n,
            },
            wasms.withdrawn,
            zkeys.withdrawn
          );

          await brazilianStormContract.withdrawn(a, b, c, input);
        } catch {}
      });

      it("should make bet", async () => {
        const sharedSecret = await genEcdhSharedKey({
          eddsa,
          privKey: keyPair.privKey,
          pubKey: coordinatorKeyPair.pubKey,
        });

        let proof = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 990000000000000000n,
            value: 10000n,
            sharedSecret,
          },
          wasms.makeBet,
          zkeys.makeBet
        );

        await brazilianStormContract.betWinner(
          proof.a,
          proof.b,
          proof.c,
          proof.input,
          1n,
          true
        );

        let user = await brazilianStormContract.users(identityCommitment);

        let decryptProof = await grothProof(
          { ciphertext: BigInt(user.balance), secret: keyPair.privKey },
          wasms.decrypt,
          zkeys.decrypt
        );

        assert(decryptProof.input[0] === "989999999999990000");

        proof = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 989999999999990000n,
            value: 10000n,
            sharedSecret,
          },
          wasms.makeBet,
          zkeys.makeBet
        );

        await brazilianStormContract.betGoals(
          proof.a,
          proof.b,
          proof.c,
          proof.input,
          1n,
          true,
          3
        );

        user = await brazilianStormContract.users(identityCommitment);

        decryptProof = await grothProof(
          { ciphertext: BigInt(user.balance), secret: keyPair.privKey },
          wasms.decrypt,
          zkeys.decrypt
        );

        assert(decryptProof.input[0] === "989999999999980000");

        proof = await grothProof(
          {
            identity: keyPair.privKey,
            currentBalance: 989999999999980000n,
            value: 10000n,
            sharedSecret,
          },
          wasms.makeBet,
          zkeys.makeBet
        );

        await brazilianStormContract.betScore(
          proof.a,
          proof.b,
          proof.c,
          proof.input,
          1n,
          3,
          1
        );

        user = await brazilianStormContract.users(identityCommitment);

        decryptProof = await grothProof(
          { ciphertext: BigInt(user.balance), secret: keyPair.privKey },
          wasms.decrypt,
          zkeys.decrypt
        );

        assert(decryptProof.input[0] === "989999999999970000");
      });
    });
  });
});
