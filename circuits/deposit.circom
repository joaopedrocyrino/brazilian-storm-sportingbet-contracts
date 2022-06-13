pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

template Deposit() {
    signal input identity;
    signal input currentBalnace;
    signal input value;

    signal output identityCommitment;
    signal output encryptedCurrentBalance;
    signal output encryptedNewBalance;

    signal newBalance;

    newBalance <== value + currentBalnace;

    component poseidon = Poseidon(1);

    poseidon.inputs[0] <== identity;

    identityCommitment <== poseidon.out;

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

component main {public [value]} = Deposit();