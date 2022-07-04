//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrazilianStorm {
    function changeBalance(
        uint256 identityCommitment,
        uint256 currentBalance,
        uint256 newBalance
    ) external;

    function payCoordinator(uint256 fee) external payable;
}
