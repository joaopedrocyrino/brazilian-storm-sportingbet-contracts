pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "./encryption.circom";

template Deposit(n) {
    signal input identity;
    signal input currentBalance;
    signal input value;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    signal newBalance;

    newBalance <== value + currentBalance;

    component balanceChange = BalanceChange(n);

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;

    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;
}

template Withdrawn(n) {
    signal input identity;
    signal input currentBalance;
    signal input value;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    signal newBalance;

    component lessEqThan = LessEqThan(252);

    lessEqThan.in[0] <== value;
    lessEqThan.in[1] <== currentBalance;

    lessEqThan.out === 1;

    newBalance <== currentBalance - value;

    component balanceChange = BalanceChange(n);

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;

    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;
}

template ClaimBetWin(n) {
    signal input identity;
    signal input currentBalance;
    signal input value;
    signal input sharedSecret;
    signal input rate;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;
    signal output encryptedBetValue;

    signal newBalance;
    signal winValue;

    winValue <== value * rate / 100;

    newBalance <== currentBalance + winValue;

    component balanceChange = BalanceChange(n);

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;

    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;

    component mimc = Encrypt(n);

    mimc.plaintext <== value;
    mimc.secret <== sharedSecret;

    encryptedBetValue <== mimc.out;
}

template MakeBet(n) {
    signal input identity;
    signal input currentBalance;
    signal input value;
    signal input sharedSecret;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;
    signal output encryptedBetValue;

    signal newBalance;

    component lessEqThan = LessEqThan(128);

    lessEqThan.in[0] <== value;
    lessEqThan.in[1] <== currentBalance;

    lessEqThan.out === 1;

    newBalance <== currentBalance - value;

    component balanceChange = BalanceChange(n);

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;

    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;

    component mimc = Encrypt(n);

    mimc.plaintext <== value;
    mimc.secret <== sharedSecret;

    encryptedBetValue <== mimc.out;
}

template BalanceChange(n) {
    signal input identity;
    signal input currentBalance;
    signal input newBalance;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    component identityHasher = Poseidon(1);
    identityHasher.inputs[0] <== identity;

    identityCommitment <== identityHasher.out;

    component mimc[2];

    mimc[0] = Encrypt(n);

    mimc[0].plaintext <== currentBalance;
    mimc[0].secret <== identity;

    mimc[1] = Encrypt(n);

    mimc[1].plaintext <== newBalance;
    mimc[1].secret <== identity;

    encryptedCurrentBalance <== mimc[0].out;
    encryptedNewBalance <== mimc[1].out;
}