#!/bin/bash

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs -d '\n')
    cd circuits

    mkdir DepositProof
    mkdir CreateUser
    mkdir Withdrawn
    mkdir ClaimBet
    mkdir MakeBet

    if [ -f ./powersOfTau28_hez_final_12.ptau ]; then
        echo "powersOfTau28_hez_final_12.ptau already exists. Skipping."
    else
        echo 'Downloading powersOfTau28_hez_final_12.ptau'
        wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_12.ptau
    fi    echo "Compiling merkleTree.circom..."

    # compile circuit

    circom merkleTreeInclusion.circom --r1cs --wasm --sym -o MerkleTree
    snarkjs r1cs info MerkleTree/merkleTreeInclusion.r1cs

    # Start a new zkey and make a contribution

    snarkjs groth16 setup MerkleTree/merkleTreeInclusion.r1cs powersOfTau28_hez_final_14.ptau MerkleTree/circuit_0000.zkey
    snarkjs zkey contribute MerkleTree/circuit_0000.zkey MerkleTree/circuit_final.zkey --name="r1" -v -e="$R1"
    snarkjs zkey contribute MerkleTree/circuit_0000.zkey MerkleTree/circuit_final.zkey --name="r2" -v -e="$R2"
    snarkjs zkey contribute MerkleTree/circuit_0000.zkey MerkleTree/circuit_final.zkey --name="r3" -v -e="$R3"
    snarkjs zkey export verificationkey MerkleTree/circuit_final.zkey MerkleTree/verification_key.json

    # generate solidity contract
    snarkjs zkey export solidityverifier MerkleTree/circuit_final.zkey ../contracts/MerkleTreeInclusionVerifier.sol

    # Start a new zkey and make a contribution

    snarkjs groth16 setup DepositProof/deposit.r1cs powersOfTau28_hez_final_10.ptau DepositProof/circuit_0000.zkey
    snarkjs zkey contribute DepositProof/circuit_0000.zkey DepositProof/circuit_final.zkey --name="r1" -v -e="$R1"
    snarkjs zkey    echo "Compiling merkleTree.circom..."

    # compile circuit

    circom merkleTreeInclusion.circom --r1cs --wasm --sym -o MerkleTree
    snarkjs r1cs info MerkleTree/merkleTreeInclusion.r1cs

    # Start a new zkey and make a contribution

    snarkjs groth16 setup MerkleTree/merkleTreeInclusion.r1cs powersOfTau28_hez_final_14.ptau MerkleTree/circuit_0000.zkey
    snarkjs zkey contribute MerkleTree/circuit_0000.zkey MerkleTree/circuit_final.zkey --name="r1" -v -e="$R1"
    snarkjs zkey contribute MerkleTree/circuit_0000.zkey MerkleTree/circuit_final.zkey --name="r2" -v -e="$R2"
    snarkjs zkey contribute MerkleTree/circuit_0000.zkey MerkleTree/circuit_final.zkey --name="r3" -v -e="$R3"
    snarkjs zkey export verificationkey MerkleTree/circuit_final.zkey MerkleTree/verification_key.json

    # generate solidity contract
    snarkjs zkey export solidityverifier MerkleTree/circuit_final.zkey ../contracts/MerkleTreeInclusionVerifier.sol
h16 setup CreateUser/createUser.r1cs powersOfTau28_hez_final_10.ptau CreateUser/circuit_0000.zkey
    snarkjs zkey contribute CreateUser/circuit_0000.zkey CreateUser/circuit_final.zkey --name="r1" -v -e="$R1"
    snarkjs zkey contribute CreateUser/circuit_0000.zkey CreateUser/circuit_final.zkey --name="r2" -v -e="$R2"
    snarkjs zkey contribute CreateUser/circuit_0000.zkey CreateUser/circuit_final.zkey --name="r3" -v -e="$R3"
    snarkjs zkey export verificationkey CreateUser/circuit_final.zkey CreateUser/verification_key.json

    # generate solidity contract
    snarkjs zkey export solidityverifier CreateUser/circuit_final.zkey ../contracts/CreateUserVerifier.sol

    echo "Compiling withdrawn.circom..."

    # compile circuit

    circom withdrawn.circom --r1cs --wasm --sym -o Withdrawn
    snarkjs r1cs info Withdrawn/withdrawn.r1cs

    # Start a new zkey and make a contribution

    snarkjs groth16 setup Withdrawn/withdrawn.r1cs powersOfTau28_hez_final_12.ptau Withdrawn/circuit_0000.zkey
    snarkjs zkey contribute Withdrawn/circuit_0000.zkey Withdrawn/circuit_final.zkey --name="r1" -v -e="$R1"
    snarkjs zkey contribute Withdrawn/circuit_0000.zkey Withdrawn/circuit_final.zkey --name="r2" -v -e="$R2"
    snarkjs zkey contribute Withdrawn/circuit_0000.zkey Withdrawn/circuit_final.zkey --name="r3" -v -e="$R3"
    snarkjs zkey export verificationkey Withdrawn/circuit_final.zkey Withdrawn/verification_key.json

    # generate solidity contract
    snarkjs zkey export solidityverifier Withdrawn/circuit_final.zkey ../contracts/WithdrawnVerifier.sol

    echo "Compiling claimBetWin.circom..."

    # compile circuit

    circom claimBetWin.circom --r1cs --wasm --sym -o ClaimBet
    snarkjs r1cs info ClaimBet/claimBetWin.r1cs

    # Start a new zkey and make a contribution

    snarkjs groth16 setup ClaimBet/claimBetWin.r1cs powersOfTau28_hez_final_12.ptau ClaimBet/circuit_0000.zkey
    snarkjs zkey contribute ClaimBet/circuit_0000.zkey ClaimBet/circuit_final.zkey --name="r1" -v -e="$R1"
    snarkjs zkey contribute ClaimBet/circuit_0000.zkey ClaimBet/circuit_final.zkey --name="r2" -v -e="$R2"
    snarkjs zkey contribute ClaimBet/circuit_0000.zkey ClaimBet/circuit_final.zkey --name="r3" -v -e="$R3"
    snarkjs zkey export verificationkey ClaimBet/circuit_final.zkey ClaimBet/verification_key.json

    # generate solidity contract
    snarkjs zkey export solidityverifier ClaimBet/circuit_final.zkey ../contracts/ClaimBetVerifier.sol

    echo "Compiling makeBet.circom..."

    # compile circuit

    circom makeBet.circom --r1cs --wasm --sym -o MakeBet
    snarkjs r1cs info MakeBet/makeBet.r1cs

    # Start a new zkey and make a contribution

    snarkjs groth16 setup MakeBet/makeBet.r1cs powersOfTau28_hez_final_12.ptau MakeBet/circuit_0000.zkey
    snarkjs zkey contribute MakeBet/circuit_0000.zkey MakeBet/circuit_final.zkey --name="r1" -v -e="$R1"
    snarkjs zkey contribute MakeBet/circuit_0000.zkey MakeBet/circuit_final.zkey --name="r2" -v -e="$R2"
    snarkjs zkey contribute MakeBet/circuit_0000.zkey MakeBet/circuit_final.zkey --name="r3" -v -e="$R3"
    snarkjs zkey export verificationkey MakeBet/circuit_final.zkey MakeBet/verification_key.json

    # generate solidity contract
    snarkjs zkey export solidityverifier MakeBet/circuit_final.zkey ../contracts/MakeBetVerifier.sol
    cd ..
fi
