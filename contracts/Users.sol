//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ICreateUserVerifier.sol";
import "./interfaces/IDepositVerifier.sol";
import "./interfaces/IWithdrawnVerifier.sol";

contract Users {
    struct User {
        /// @dev user balance encrypted using user's identity
        uint256 balance;
        /// @dev used to generate shared secret between coordinator and user
        uint8[32][2] pubKey;
        /// @dev used to check if user actually exists or if its default value
        bool isActive;
    }

    /// @dev username hash => bool already in use
    mapping(uint256 => bool) public usernames;

    /// @dev identity commitment => user
    mapping(uint256 => User) public users;

    /// @dev zero knowledge verifier on create user
    ICreateUserVerifier private createUserVerifier;
    /// @dev zero knowledge verifier on deposit funds
    IDepositVerifier private depositVerifier;
    /// @dev zero knowledge verifier on withdrawn funds
    IWithdrawnVerifier private withdrawnVerifier;

    constructor(
        address _createUserVerifier,
        address _depositVerifier,
        address _withdrawnVerifier
    ) {
        createUserVerifier = ICreateUserVerifier(_createUserVerifier);
        depositVerifier = IDepositVerifier(_depositVerifier);
        withdrawnVerifier = IWithdrawnVerifier(_withdrawnVerifier);
    }

    event UserCreated(uint256 identityCommitment, uint8[32][2] pubKey);

    function _changeBalance(
        uint256 identityCommitment,
        uint256 currentBalance,
        uint256 newBalance
    ) internal {
        User storage user = users[identityCommitment];

        require(user.balance == currentBalance, "Invalid current balance");

        user.balance = newBalance;
    }

    function _createUser(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input,
        uint8[32][2] memory pubKey
    ) internal {
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
}
