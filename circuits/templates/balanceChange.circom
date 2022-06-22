pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/mimc.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "./merkleTree.circom";

template Deposit() {
    signal input identity;
    signal input currentBalance;
    signal input value;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    signal newBalance;

    newBalance <== value + currentBalance;

    component balanceChange = BalanceChange();

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;
    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;
}

template Withdrawn() {
    signal input identity;
    signal input currentBalance;
    signal input value;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    signal newBalance;

    component lessEqThan = LessEqThan(128);

    lessEqThan.in[0] <== value;
    lessEqThan.in[1] <== currentBalance;

    lessEqThan.out === 1;

    newBalance <== currentBalance - value;

    component balanceChange = BalanceChange();

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;
    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;
}

template ClaimBetWin() {
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

    winValue <== value * rate;

    newBalance <== currentBalance + winValue;

    component balanceChange = BalanceChange();

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;
    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;

    component mimc = MiMC7(90);

    mimc.x_in <== value;
    mimc.k <== sharedSecret;

    encryptedBetValue <== mimc.out;
}

template MakeBet() {
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

    component balanceChange = BalanceChange();

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;
    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;

    component mimc = MiMC7(90);

    mimc.x_in <== value;
    mimc.k <== sharedSecret;

    encryptedBetValue <== mimc.out;
}

template BalanceChange() {
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

    mimc[0] = MiMC7(90);

    mimc[0].x_in <== currentBalance;
    mimc[0].k <== identity;

    encryptedCurrentBalance <== mimc[0].out;

    mimc[1] = MiMC7(90);

    mimc[1].x_in <== newBalance;
    mimc[1].k <== identity;

    encryptedNewBalance <== mimc[0].out;
}