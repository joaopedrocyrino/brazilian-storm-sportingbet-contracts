pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/mimc.circom";

template Encrypt(n) {
    /// @dev priv key
    signal input secret;
    /// @dev decrypted data
    signal input plaintext;

    /// @dev encrypted data
    signal output out;

    /// @dev calculate the initialization vector
    component iv = MiMC7(91);

    iv.x_in <== secret;
    iv.k <== 0;

    signal ciphertext[n + 1];
    component ciphertextEncrypter[n];

    ciphertext[0] <== iv.out;

    for(var i = 0; i < n; i++) {
        /// @dev in each interation it initializes a mimc
        /// and hashes the iv + previous hash + i
        /// and saves the sum of this hash and the previous
        ciphertextEncrypter[i] = MiMC7(91);

        ciphertextEncrypter[i].x_in <== secret;
        ciphertextEncrypter[i].k <== iv.out + ciphertext[i] + i;

        ciphertext[i + 1] <== ciphertextEncrypter[i].out + ciphertext[i];
    }

    /// @dev gets the last hash calculated and sums on the decrypted data
    out <== plaintext + ciphertext[n];
}

template Decrypt(n) {
    /// @dev encrypted data
    signal input ciphertext;
    /// @dev priv key
    signal input secret;

    /// @dev decrypted data
    signal output out;

    /// @dev calculate the initialization vector
    component iv = MiMC7(91);

    iv.x_in <== secret;
    iv.k <== 0;

    signal plaintext[n + 1];
    component plaintextEncrypter[n];

    plaintext[0] <== iv.out;

    for(var i = 0; i < n; i++) {
        // @dev in each interation it initializes a mimc
        /// and hashes the iv + previous hash + i
        /// and saves the sum of this hash and the previous
        plaintextEncrypter[i] = MiMC7(91);

        plaintextEncrypter[i].x_in <== secret;
        plaintextEncrypter[i].k <== iv.out + plaintext[i] + i;

        plaintext[i + 1] <== plaintextEncrypter[i].out + plaintext[i];
    }

    /// @dev gets the encrypted data and subtract 
    /// last hash calculated to get the decrypted data
    out <== ciphertext - plaintext[n];
}
