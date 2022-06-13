pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

template CreateUser() {
    signal input identity;

    signal output identityCommitment;
    signal output encryptedInitialBalance;

    component poseidon = Poseidon(1);

    poseidon.inputs[0] <== identity;

    identityCommitment <== poseidon.out;

    component mimc = MiMC7(90);

    mimc.x_in <== 0;
    mimc.k <== identity;

    encryptedInitialBalance <== mimc.out;  
}

component main = CreateUser();