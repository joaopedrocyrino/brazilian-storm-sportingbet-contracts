pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/mimc.circom";

template Encrypt(n) {
    signal input secret;
    signal input plaintext;

    signal output out;

    component iv = MiMC7(91);

    iv.x_in <== secret;
    iv.k <== 0;

    signal ciphertext[n + 1];
    component ciphertextEncrypter[n];

    ciphertext[0] <== iv.out;

    for(var i = 0; i < n; i++) {
        ciphertextEncrypter[i] = MiMC7(91);

        ciphertextEncrypter[i].x_in <== secret;
        ciphertextEncrypter[i].k <== iv.out + ciphertext[i] + i;

        ciphertext[i + 1] <== ciphertextEncrypter[i].out + ciphertext[i];
    }

    out <== plaintext + ciphertext[n];
}

template Decrypt(n) {
    signal input ciphertext;
    signal input secret;

    signal output out;

    component iv = MiMC7(91);

    iv.x_in <== secret;
    iv.k <== 0;

    signal plaintext[n + 1];
    component plaintextEncrypter[n];

    plaintext[0] <== iv.out;

    for(var i = 0; i < n; i++) {
        plaintextEncrypter[i] = MiMC7(91);

        plaintextEncrypter[i].x_in <== secret;
        plaintextEncrypter[i].k <== iv.out + plaintext[i] + i;

        plaintext[i + 1] <== plaintextEncrypter[i].out + plaintext[i];
    }

    out <== ciphertext - plaintext[n];


    // signal plaintext[n - 1];

    // component mimc[n - 1];

    // for(var i = 1; i < n; i++) {
    //     mimc[i - 1] = MiMC7(91);

    //     mimc[i - 1].x_in <== secret;
    //     mimc[i - 1].k <== ciphertext[0] + i;

    //     plaintext[i - 1] <== mimc[i - 1].out + ciphertext[i - 1];
    // }

    // out <== ciphertext[n] - plaintext[n - 2];

    // component hasher = MiMC7(91);

    // hasher.x_in <== secret;
    // hasher.k <== cyphertext[0];

    // out <== cyphertext[1] - hasher.out;
}
