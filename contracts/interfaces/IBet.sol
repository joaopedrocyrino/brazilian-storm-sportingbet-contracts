//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Matches.sol";

interface IBet {
    function closeMatches(Matches.CloseMatches[] memory matchesToClose)
        external;
}
