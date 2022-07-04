//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/ICreateUserVerifier.sol";
import "./interfaces/IDepositVerifier.sol";
import "./interfaces/IWithdrawnVerifier.sol";

contract BrazilianStormSportingbet {
    using Counters for Counters.Counter;

    struct User {
        uint256 balance;
        uint8[32][2] pubKey;
        bool isActive;
    }

    mapping(uint256 => bool) public usernames;
    mapping(uint256 => User) public users;

    address private coordinator;
    uint8[32][2] public coordinatorPubKey;

    ICreateUserVerifier private createUserVerifier;
    IDepositVerifier private depositVerifier;
    IWithdrawnVerifier private withdrawnVerifier;

    address private betContract;

    constructor(
        address _createUserVerifier,
        address _depositVerifier,
        address _withdrawnVerifier,
        uint8[32][2] memory _coordinatorPubKey
    ) {
        coordinator = msg.sender;
        coordinatorPubKey = _coordinatorPubKey;

        createUserVerifier = ICreateUserVerifier(_createUserVerifier);
        depositVerifier = IDepositVerifier(_depositVerifier);
        withdrawnVerifier = IWithdrawnVerifier(_withdrawnVerifier);
    }

    event UserCreated(uint256 identityCommitment, uint8[32][2] pubKey);

    modifier onlyCoordinator() {
        require(msg.sender == coordinator, "Only coordinator allowed");
        _;
    }

    modifier onlyContracts() {
        require(msg.sender == betContract, "Only contracts allowed");
        _;
    }

    function setContractAdresses(address _betContract)
        external
        onlyCoordinator
    {
        betContract = _betContract;
    }

    function createUser(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input,
        uint8[32][2] memory pubKey
    ) external {
        bool isValidProof = createUserVerifier.verifyProof(a, b, c, input);

        require(isValidProof, "Invalid proof");
        require(!usernames[input[1]], "Username is taken");

        usernames[input[1]] = true;

        users[input[0]] = User(input[2], pubKey, true);

        emit UserCreated(input[0], pubKey);
    }

    function deposit(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external payable {
        bool isValidProof = depositVerifier.verifyProof(a, b, c, input);

        require(isValidProof, "Invalid proof");

        User storage user = users[input[0]];

        require(
            user.balance == input[1] && msg.value == input[3],
            "Invalid deposit"
        );

        user.balance = input[2];
    }

    function withdrawn(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external payable {
        bool isValidProof = withdrawnVerifier.verifyProof(a, b, c, input);

        require(isValidProof, "Invalid proof");

        User storage user = users[input[0]];

        require(user.balance == input[1], "Invalid withdrawn");

        user.balance = input[2];

        payable(msg.sender).transfer(input[3]);
    }

    function changeBalance(
        uint256 identityCommitment,
        uint256 currentBalance,
        uint256 newBalance
    ) external onlyContracts {
        User storage user = users[identityCommitment];

        require(user.balance == currentBalance, "Invalid current balance");

        user.balance = newBalance;
    }

    function payCoordinator(uint256 fee) external payable onlyContracts {
        payable(coordinator).transfer(fee);
    }
}
