pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "./encryption.circom";

/// @dev n represents the size of mimc loop on encryption.
template Deposit(n) {
    /// @dev identity represents the user's
    /// private key.
    signal input identity;
    /// @dev currentBalance represents the user's
    /// current balance.
    signal input currentBalance;
    /// @dev value represents the amount of tokens
    /// sent to the contract.
    signal input value;

    /// @dev the hash of the private key
    signal output identityCommitment;
    /// @dev represents the user's
    /// current balance hash.
    signal output encryptedCurrentBalance;
    /// @dev the hash of user balance after deposit.
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
    /// @dev identity represents the user's
    /// private key.
    signal input identity;
    /// @dev currentBalance represents the user's
    /// current balance.
    signal input currentBalance;
    /// @dev value represents the amount of tokens
    /// that will be removed from contract.
    signal input value;

    /// @dev user's priv key hash 
    signal output identityCommitment;
    /// @dev user's current balance hash.
    signal output encryptedCurrentBalance;
    /// @dev user's new balance hash.
    signal output encryptedNewBalance;

    signal newBalance;

    /// @dev assert that value been withdrawn is
    /// less or equal than the current balance
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
    /// @dev user's priv key
    signal input identity;
    /// @dev user's current balance
    signal input currentBalance;
    /// @dev user's betted value
    signal input value;
    /// @dev user's the ecdh shared secret with coordinator
    signal input sharedSecret;
    /// @dev the rate represents how many tokens 
    /// for each 100 tokens betted the users win
    signal input rate;

    /// @dev user's priv key hash 
    signal output identityCommitment;
    /// @dev user's current balance hash.
    signal output encryptedCurrentBalance;
    /// @dev user's new balance hash.
    signal output encryptedNewBalance;
    /// @dev user's betted value hash.
    signal output encryptedBetValue;

    signal newBalance;
    signal winValue;

    /// @dev the amount that bust me added
    /// is the original bet value plus the
    // returns for each token betted
    winValue <== value * rate / 100;

    newBalance <== currentBalance + winValue;

    component balanceChange = BalanceChange(n);

    balanceChange.identity <== identity;
    balanceChange.currentBalance <== currentBalance;
    balanceChange.newBalance <== newBalance;

    identityCommitment <== balanceChange.identityCommitment;

    encryptedCurrentBalance <== balanceChange.encryptedCurrentBalance;
    encryptedNewBalance <== balanceChange.encryptedNewBalance;

    /// @dev encrypts the betted value with a 
    /// secret that only coordinator can decrypt
    component mimc = Encrypt(n);

    mimc.plaintext <== value;
    mimc.secret <== sharedSecret;

    encryptedBetValue <== mimc.out;
}

template MakeBet(n) {
    /// @dev user's priv key
    signal input identity;
    /// @dev user's current balance
    signal input currentBalance;
    /// @dev user's betted value
    signal input value;
    /// @dev user's the ecdh shared secret with coordinator
    signal input sharedSecret;

    /// @dev user's priv key hash 
    signal output identityCommitment;
    /// @dev user's current balance hash.
    signal output encryptedCurrentBalance;
    /// @dev user's new balance hash.
    signal output encryptedNewBalance;
    /// @dev user's betted value hash.
    signal output encryptedBetValue;

    signal newBalance;

    /// @dev assert that value been betted is
    /// less or equal than the current balance
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

    /// @dev encrypts the betted value with a 
    /// secret that only coordinator can decrypt
    component mimc = Encrypt(n);

    mimc.plaintext <== value;
    mimc.secret <== sharedSecret;

    encryptedBetValue <== mimc.out;
}

/// @dev n represents the size of mimc loop on encryption.
template BalanceChange(n) {
    /// @dev user's private key.
    signal input identity;
    /// @dev user's current balance.
    signal input currentBalance;
    /// @dev user's new balance.
    signal input newBalance;

    /// @dev user's private key hash.
    signal output identityCommitment;
    /// @dev user's current balance hash.
    signal output encryptedCurrentBalance;
    /// @dev user's new balance hash.
    signal output encryptedNewBalance;

    /// @dev hashes the user's priv key
    component identityHasher = Poseidon(1);
    identityHasher.inputs[0] <== identity;

    identityCommitment <== identityHasher.out;

    /// @dev One encrypter for current balance
    /// and other for new balance
    component mimc[2];

    /// @dev sets size of mimc loop on encryption
    mimc[0] = Encrypt(n);

    mimc[0].plaintext <== currentBalance;
    mimc[0].secret <== identity;

    mimc[1] = Encrypt(n);

    mimc[1].plaintext <== newBalance;
    mimc[1].secret <== identity;

    encryptedCurrentBalance <== mimc[0].out;
    encryptedNewBalance <== mimc[1].out;
}