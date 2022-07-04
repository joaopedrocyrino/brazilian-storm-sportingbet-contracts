//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dto.sol";

interface IBet {
    function closeMatches(Dto.CloseMatches[] memory matchesToClose)
        external;
}
