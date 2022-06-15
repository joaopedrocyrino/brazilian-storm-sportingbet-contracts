import { ethers } from "hardhat";
const { poseidonContract } = require("circomlibjs");

async function main() {
  const DepositVerifier = await ethers.getContractFactory("DepositVerifier");
  const depositVerifier = await DepositVerifier.deploy();

  await depositVerifier.deployed();

  console.log("\nDeposit Verifier deployed to:", depositVerifier.address);

  const MerkleTreeInclusionVerifier = await ethers.getContractFactory(
    "MerkleTreeInclusionVerifier"
  );
  const merkleTreeInclusionVerifier =
    await MerkleTreeInclusionVerifier.deploy();

  await merkleTreeInclusionVerifier.deployed();

  console.log(
    "\nMerkle Tree Inclusion Verifier deployed to:",
    merkleTreeInclusionVerifier.address
  );

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

  const PoseidonT3 = await ethers.getContractFactory(
    poseidonContract.generateABI(2),
    poseidonContract.createCode(2)
  );
  const poseidonT3 = await PoseidonT3.deploy();
  await poseidonT3.deployed();

  console.log("\nPoseidonT3 deployed to:", poseidonT3.address);

  const IncrementalBinaryTree = await ethers.getContractFactory(
    "IncrementalBinaryTree",
    {
      libraries: {
        PoseidonT3: poseidonT3.address,
      },
    }
  );
  const incrementalBinaryTree = await IncrementalBinaryTree.deploy();
  await incrementalBinaryTree.deployed();

  console.log(
    "\nIncremental Binary Tree deployed to:",
    incrementalBinaryTree.address
  );

  const BrazilianStormSportingbet = await ethers.getContractFactory(
    "BrazilianStormSportingbet",
    {
      libraries: {
        IncrementalBinaryTree: incrementalBinaryTree.address,
      },
    }
  );
  const brazilianStormSportingbet = await BrazilianStormSportingbet.deploy(
    depositVerifier.address,
    merkleTreeInclusionVerifier.address,
    createUserVerifier.address,
    withdrawnVerifier.address,
    32
  );

  await brazilianStormSportingbet.deployed();

  console.log(
    "\nBrazilian Storm Sportingbet deployed to:",
    brazilianStormSportingbet.address
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
