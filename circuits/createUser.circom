pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

template CreateUser() {
    signal input username;
    signal input password;

    signal output identityCommitment;
    signal output usernameCommitment;
    signal output encryptedInitialBalance;

    component poseidonT3 = Poseidon(2);

    poseidonT3.inputs[0] <== username;
    poseidonT3.inputs[1] <== password;

    component poseidon[2];
    
    poseidon[0] = Poseidon(1);

    poseidon[0].inputs[0] <== poseidonT3.out;

    identityCommitment <== poseidon[0].out;

    poseidon[1] = Poseidon(1);

    poseidon[1].inputs[0] <== identity;

    usernameCommitment <== poseidon[1].out;

    component mimc = MiMC7(90);

    mimc.x_in <== 0;
    mimc.k <== identity;

    encryptedInitialBalance <== mimc.out;  
}

component main = CreateUser();