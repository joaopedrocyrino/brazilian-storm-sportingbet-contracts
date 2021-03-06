import * as dotenv from "dotenv";
import { ethers } from "hardhat";
import { genKeypair } from "../test/utils/encryption";
const { buildEddsa } = require("circomlibjs");

async function main() {
  const eddsa = await buildEddsa();
  const keyPair = await genKeypair(
    eddsa,
    process.env.COORDINATOR_USERNAME || "",
    process.env.COORDINATOR_PASSWORD || ""
  );

  const DepositVerifier = await ethers.getContractFactory("DepositVerifier");
  const depositVerifier = await DepositVerifier.deploy();

  await depositVerifier.deployed();

  console.log("\nDeposit Verifier deployed to:", depositVerifier.address);

  const CreateUserVerifier = await ethers.getContractFactory(
    "CreateUserVerifier"
  );
  const createUserVerifier = await CreateUserVerifier.deploy();

  await createUserVerifier.deployed();

  console.log("\nCreateUser Verifier deployed to:", createUserVerifier.address);

  const WithdrawnVerifier = await ethers.getContractFactory(
    "WithdrawnVerifier"
  );
  const withdrawnVerifier = await WithdrawnVerifier.deploy();

  await withdrawnVerifier.deployed();

  console.log("\nWithdrawn Verifier deployed to:", withdrawnVerifier.address);

  const MakeBetContract = await ethers.getContractFactory("MakeBetVerifier");

  const betContract = await MakeBetContract.deploy();
  await betContract.deployed();

  console.log("\nWMake Bet Contract deployed to:", betContract.address);

  const ClaimBetContract = await ethers.getContractFactory("ClaimBetVerifier");

  const claimBetContract = await ClaimBetContract.deploy();
  await claimBetContract.deployed();

  console.log("\nWClaim Bet Contract deployed to:", claimBetContract.address);

  const BrazilianStorm = await ethers.getContractFactory(
    "BrazilianStormSportingbet"
  );

  const brazilianStormContract = await BrazilianStorm.deploy(
    createUserVerifier.address,
    depositVerifier.address,
    withdrawnVerifier.address,
    [
      // @ts-ignore
      Array.from(keyPair.pubKey[0]),
      // @ts-ignore
      Array.from(keyPair.pubKey[1]),
    ]
  );

  await brazilianStormContract.deployed();

  console.log(
    "\brazilianStormContract deployed to:",
    brazilianStormContract.address
  );

  const Matches = await ethers.getContractFactory("Matches");

  const matchesContract = await Matches.deploy();

  console.log("\nMatches deployed to:", matchesContract.address);

  const Bet = await ethers.getContractFactory("Bets");

  const betsContract = await Bet.deploy(
    betContract.address,
    claimBetContract.address,
    brazilianStormContract.address,
    matchesContract.address
  );

  console.log("\nBet deployed to:", betsContract.address);

  brazilianStormContract.setContractAdresses(betsContract.address);
  matchesContract.setContractAdresses(betsContract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
