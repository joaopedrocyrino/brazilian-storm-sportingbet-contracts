//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@zk-kit/incremental-merkle-tree.sol/contracts/IncrementalBinaryTree.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IMerkleTreeInclusionVerifier.sol";
import "./interfaces/IDepositVerifier.sol";
import "./interfaces/ICreateUserVerifier.sol";
import "./interfaces/IWithdrawnVerifier.sol";
// import {PoseidonT2} from "./Poseidon.sol";

contract BrazilianStormSportingbet {
    using IncrementalBinaryTree for IncrementalTreeData;
    using Counters for Counters.Counter;

    struct BetOption {
        uint256 id;
        bool open;
        string title;
        string description;
        uint256 returnValue;
    }

    struct Bet {
        uint256 id;
        uint256 betOptionId;
        bool finished;
        bool win;
        uint256 value;
    }

    address private owner;

    IncrementalTreeData public users;

    IDepositVerifier public depositVerifier;
    IMerkleTreeInclusionVerifier public merkleTreeInclusionVerifier;
    ICreateUserVerifier public createUserVerifier;
    IWithdrawnVerifier public withdrawnVerifier;

    mapping(uint256 => bool) public usernames;
    mapping(uint256 => uint256) public balances;
    mapping(uint256 => uint256) public treeIndex;

    constructor(
        address _depositVerifier,
        address _merkleTreeVerifier,
        address _createUserVerifier,
        address _withdrawnVerifier,
        uint8 depth
    ) {
        createUserVerifier = ICreateUserVerifier(_createUserVerifier);
        depositVerifier = IDepositVerifier(_depositVerifier);
        withdrawnVerifier = IWithdrawnVerifier(_withdrawnVerifier);
        merkleTreeInclusionVerifier = IMerkleTreeInclusionVerifier(
            _merkleTreeVerifier
        );

        users.init(depth, 0);

        owner = msg.sender;
    }

    event UserCreated(uint256 identityCommitment, uint256 root);
    event UserDeleted(uint256 identityCommitment, uint256 root);

    function isUser(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) internal view returns (uint256) {
        bool isIncluded = merkleTreeInclusionVerifier.verifyProof(
            a,
            b,
            c,
            input
        );

        require(isIncluded && input[0] == users.root, "Not authorized");

        return input[1];
    }

    function createUser(
        uint256 username,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) external {
        require(!usernames[username], "Username is taken");

        uint256 leafIndex = users.numberOfLeaves;

        bool isVerified = createUserVerifier.verifyProof(a, b, c, input);

        require(isVerified, "Invalid proof");

        users.insert(input[0]);

        usernames[username] = true;
        treeIndex[input[0]] = leafIndex;

        balances[input[0]] = input[1];

        uint256 newRoot = users.root;

        emit UserCreated(input[0], newRoot);
    }

    function deposit(
        uint256[2] memory merkleA,
        uint256[2][2] memory merkleB,
        uint256[2] memory merkleC,
        uint256[2] memory merkleInput,
        uint256[2] memory depositA,
        uint256[2][2] memory depositB,
        uint256[2] memory depositC,
        uint256[4] memory depositInput
    ) external payable {
        uint256 identityCommitment = isUser(
            merkleA,
            merkleB,
            merkleC,
            merkleInput
        );

        bool isValidDeposit = depositVerifier.verifyProof(
            depositA,
            depositB,
            depositC,
            depositInput
        );

        require(
            isValidDeposit &&
                identityCommitment == depositInput[0] &&
                balances[identityCommitment] == depositInput[1] &&
                msg.value == depositInput[3],
            "Invalid deposit"
        );

        balances[identityCommitment] = depositInput[2];
    }

    function withdrawn(
        uint256[2] memory merkleA,
        uint256[2][2] memory merkleB,
        uint256[2] memory merkleC,
        uint256[2] memory merkleInput,
        uint256[2] memory withdrawnA,
        uint256[2][2] memory withdrawnB,
        uint256[2] memory withdrawnC,
        uint256[4] memory withdrawnInput,
        uint256 withdrawnValue
    ) external payable {
        uint256 identityCommitment = isUser(
            merkleA,
            merkleB,
            merkleC,
            merkleInput
        );

        bool isValidWithdrawn = withdrawnVerifier.verifyProof(
            withdrawnA,
            withdrawnB,
            withdrawnC,
            withdrawnInput
        );

        require(
            isValidWithdrawn &&
                identityCommitment == withdrawnInput[0] &&
                balances[identityCommitment] == withdrawnInput[1] &&
                withdrawnValue == withdrawnInput[3],
            "Invalid withdrawn"
        );

        balances[identityCommitment] = withdrawnInput[2];
    }
}
