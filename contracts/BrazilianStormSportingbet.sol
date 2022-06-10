//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@zk-kit/incremental-merkle-tree.sol/contracts/IncrementalBinaryTree.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./MerkleTreeInclusionVerifier.sol";
import "./DepositVerifier.sol";

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
    DepositVerifier public depositVerifier;
    MerkleTreeInclusionVerifier public merkleTreeInclusionVerifier;

    mapping(uint256 => bool) public usernames;
    mapping(uint256 => uint256) public balances;
    mapping(uint256 => uint256) public treeIndex;

    constructor(address _depositVerifier, address _merkleTreeVerifier, uint8 depth) {
        depositVerifier = DepositVerifier(_depositVerifier);
        merkleTreeInclusionVerifier = MerkleTreeInclusionVerifier(_merkleTreeVerifier);

        users.init(depth, 0);

        owner = msg.sender;
    }

    event UserCreated(uint256 identityCommitment, uint256 root);
    event UserDeleted(uint256 identityCommitment, uint256 root);

    function createUser(uint256 username, uint256 identityCommitment) external {
        require(!usernames[username], "Username is taken");

        users.insert(identityCommitment);

        uint256 newRoot = users.root;

        emit UserCreated(identityCommitment, newRoot);
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
        bool isIncluded = merkleTreeInclusionVerifier.verifyProof(
            merkleA,
            merkleB,
            merkleC,
            merkleInput
        );

        require(isIncluded && input[0] == users.root, "Not authorized");

        bool isValidDeposit = depositVerifier.verifyProof(
            depositA,
            depositB,
            depositC,
            depositInput
        );
        
        require(isValidDeposit && balances[depositInput[0]] == depositInput[1] && msg.value == depositInput[3], "Invalid deposit");

        balances[depositInput[0]] = depositInput[2];
    }
}
