pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/mimc.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "./merkleTree.circom"

template Deposit(n) {
    signal input identity;
    signal input pathElements[n];
    signal input pathIndex[n];
    signal input currentBalnace;
    signal input value;

    signal output identityCommitment;
    signal output root;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    signal newBalance;

    newBalance <== value + currentBalnace;

    component balanceChange = BalanceChange(n);

    balanceChange.identity <== identity;
    balanceChange.currentBalnace <== currentBalnace;
    balanceChange.newBalance <== newBalance;

    for (var i = 0; i < n; i++) {
       balanceChange.pathElements[i] <== pathElements[i];
       balanceChange.pathIndex[i] <== pathIndex[i];
    }

    identityCommitment <== balanceChange.identityCommitment;
    root <== balanceChange.root;
    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;
}

template Withdrawn(n) {
    signal input identity;
    signal input pathElements[n];
    signal input pathIndex[n];
    signal input currentBalnace;
    signal input value;

    signal output identityCommitment;
    signal output root;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    signal newBalance;

    component lessEqThan = LessEqThan(128);

    lessEqThan.in[0] <== value;
    lessEqThan.in[1] <== currentBalnace;

    lessEqThan.out === 1;

    newBalance <== currentBalnace - value;

    component balanceChange = BalanceChange(n);

    balanceChange.identity <== identity;
    balanceChange.currentBalnace <== currentBalnace;
    balanceChange.newBalance <== newBalance;

    for (var i = 0; i < n; i++) {
       balanceChange.pathElements[i] <== pathElements[i];
       balanceChange.pathIndex[i] <== pathIndex[i];
    }

    identityCommitment <== balanceChange.identityCommitment;
    root <== balanceChange.root;
    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;
}

template BalanceChange(n) {
    signal input identity;
    signal input pathElements[n];
    signal input pathIndex[n];
    signal input currentBalnace;
    signal input newBalance;

    signal output identityCommitment;
    signal output root;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    component merkleTreeInclusionProof = MerkleTreeInclusionProof(n);

    merkleTreeInclusionProof.identity <== identity;

    for (var i = 0; i < n; i++) {
       merkleTreeInclusionProof.pathElements[i] <== pathElements[i];
       merkleTreeInclusionProof.pathIndex[i] <== pathIndex[i];
    }

    identityCommitment <== merkleTreeInclusionProof.identityCommitment;
    root <== merkleTreeInclusionProof.root;

    component mimc[2];

    mimc[0] = MiMC7(90);

    mimc[0].x_in <== currentBalnace;
    mimc[0].k <== identity;

    encryptedCurrentBalance <== mimc[0].out;

    mimc[1] = MiMC7(90);

    mimc[1].x_in <== newBalance;
    mimc[1].k <== identity;

    encryptedNewBalance <== mimc[0].out;
}