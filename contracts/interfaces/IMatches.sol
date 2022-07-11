//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Matches.sol";

interface IMatches {
    function getMatch(uint256 champId, uint256 matchId)
        external
        view
        returns (Matches.Match memory);
}
