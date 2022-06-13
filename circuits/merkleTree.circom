pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template MerkleTreeInclusionProof(n) {
    signal input identity;
    signal input pathElements[n];
    signal input pathIndex[n];

    signal output root;
    signal output identityCommitment;

    component hashers[n];
    component mux[n];

    component identityHasher = Poseidon(1);
    identityHasher.inputs[0] <== identity;

    signal hashs[n + 1];
    hashs[0] <== identityHasher.out;

    for (var i = 0; i < n; i++) {
        hashers[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][1] <== pathElements[i];
        mux[i].c[1][0] <== pathElements[i];

        mux[i].c[0][0] <== hashs[i];
        mux[i].c[1][1] <== hashs[i];

        mux[i].s <== pathIndex[i];

        hashers[i].inputs[0] <== mux[i].out[0];
        hashers[i].inputs[1] <== mux[i].out[1];

        hashs[i + 1] <== hashers[i].out;
    }

    root <== hashs[n];
    identityCommitment <== identityHasher.out;
}

component main = MerkleTreeInclusionProof(32);