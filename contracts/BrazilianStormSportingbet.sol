//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@zk-kit/incremental-merkle-tree.sol/contracts/IncrementalBinaryTree.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IMerkleTreeInclusionVerifier.sol";
import "./interfaces/IDepositVerifier.sol";
import "./interfaces/ICreateUserVerifier.sol";
import "./interfaces/IWithdrawnVerifier.sol";

contract BrazilianStormSportingbet {
    using IncrementalBinaryTree for IncrementalTreeData;
    using Counters for Counters.Counter;

    struct WinnerBet {
        uint256 id;
        bool houseWins;
        uint256 better;
        uint256 value;
        uint8 round;
        uint16 season;
    }

    struct GoalsBet {
        uint256 id;
        bool house;
        uint256 better;
        uint256 value;
        uint8 round;
        uint16 season;
        uint8 goals;
    }

    struct ScoreBet {
        uint256 id;
        uint8 house;
        uint8 visitor;
        uint256 better;
        uint256 value;
        uint8 round;
        uint16 season;
    }

    IncrementalTreeData public users;

    IDepositVerifier public depositVerifier;
    IMerkleTreeInclusionVerifier public merkleTreeInclusionVerifier;
    ICreateUserVerifier public createUserVerifier;
    IWithdrawnVerifier public withdrawnVerifier;

    mapping(uint256 => bool) public usernames;
    mapping(uint256 => uint256) public balances;
    mapping(uint256 => uint256) public treeIndex;
    mapping(uint256 => mapping(uint256 => WinnerBet)) winnerBets;

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
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input
    ) external payable {
        bool isValidDeposit = depositVerifier.verifyProof(a, b, c, input);

        require(
            isValidDeposit &&
                balances[input[0]] == input[2] &&
                input[1] == users.root &&
                msg.value == input[4],
            "Invalid deposit"
        );

        balances[input[0]] = input[3];
    }

    function withdrawn(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input
    ) external payable {
        bool isValidWithdrawn = withdrawnVerifier.verifyProof(a, b, c, input);

        require(
            isValidWithdrawn &&
                balances[input[0]] == input[2] &&
                input[1] == users.root,
            "Invalid withdrawn"
        );

        balances[input[0]] = input[3];

        payable(msg.sender).transfer(input[4]);
    }
}
