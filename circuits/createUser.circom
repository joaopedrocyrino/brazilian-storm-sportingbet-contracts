pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mimc.circom";
include "./templates/encryption.circom";

template CreateUser(n) {
    /// @dev username hash
    signal input username;
    /// @dev password hash
    signal input password;

    /// @dev the hash of the priv key generated with
    /// username and password
    signal output identityCommitment;
    /// @dev the hash of the username hash
    signal output usernameCommitment;
    /// @dev 0 encrypted using user's priv key
    signal output encryptedInitialBalance;

    /// @dev to generate user's priv key
    component poseidonT3 = Poseidon(2);

    poseidonT3.inputs[0] <== username;
    poseidonT3.inputs[1] <== password;

    component poseidon[2];
    
    poseidon[0] = Poseidon(1);
    
    /// @dev hashes the priv key
    poseidon[0].inputs[0] <== poseidonT3.out;

    identityCommitment <== poseidon[0].out;

    poseidon[1] = Poseidon(1);

    /// @dev hashes the username
    poseidon[1].inputs[0] <== username;

    usernameCommitment <== poseidon[1].out;

    /// @dev it hashes 0 with the priv key
    component encrypt = Encrypt(n);

    encrypt.secret <== poseidonT3.out;
    encrypt.plaintext <== 0;

    encryptedInitialBalance <== encrypt.out;  
}

component main = CreateUser(5);