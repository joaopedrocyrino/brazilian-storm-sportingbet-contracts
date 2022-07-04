//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Dto {
    struct Match {
        uint256 id;
        string house;
        string visitor;
        uint256 start;
        uint8 houseGoals;
        uint8 visitorGoals;
        bool closed;
        bool resultsFullfilled;
    }

    struct CloseMatches {
        uint256 champId;
        uint256 matchId;
        uint16 winnerMultiplier;
        uint16 scoreMultiplier;
        uint16 goalsMultiplier;
        uint256 coordinatorFee;
    }
}
