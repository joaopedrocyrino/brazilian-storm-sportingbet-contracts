//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dto.sol";

interface IMatches {
    function getMatch(uint256 champId, uint256 matchId)
        external
        view
        returns (Dto.Match memory);
}
