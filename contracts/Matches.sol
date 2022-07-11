//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IBet.sol";

contract Matches {
    using Counters for Counters.Counter;

    struct Championship {
        string name;
        uint16 season;
        string country;
    }

    struct Match {
        string house;
        string visitor;
        uint256 start;
        uint8 houseGoals;
        uint8 visitorGoals;
        bool closed;
        bool resultsFullfilled;
    }

    struct Fullfill {
        uint8 house;
        uint8 visitor;
        uint256 matchId;
        uint256 champId;
    }

    struct CloseMatches {
        uint256 champId;
        uint256 matchId;
        uint16 winnerMultiplier;
        uint16 scoreMultiplier;
        uint16 goalsMultiplier;
        uint256 coordinatorFee;
    }

    Counters.Counter public champIds;

    mapping(uint256 => mapping(uint256 => Match)) public matches;
    mapping(uint256 => Counters.Counter) public matchIds;

    address private coordinator;
    IBet private betsContract;

    constructor() {
        coordinator = msg.sender;
    }

    event ChampionshipInserted(
        uint256 id,
        string name,
        uint16 season,
        string country
    );

    event MatchInserted(
        uint256 id,
        uint256 champId,
        string house,
        string visitor,
        uint256 start
    );

    modifier onlyCoordinator() {
        require(msg.sender == coordinator, "Only coordinator allowed");
        _;
    }

    function setContractAdresses(
        address _betContract
    ) external onlyCoordinator {
        betsContract = IBet(_betContract);
    }

    function insertChampionships(Championship[] memory champs)
        external
        onlyCoordinator
    {
        for (uint256 i = 0; i < champs.length; i++) {
            emit ChampionshipInserted(
                champIds.current(),
                champs[i].name,
                champs[i].season,
                champs[i].country
            );

            champIds.increment();
        }
    }

    function insertMatches(uint256 champId, Match[] memory matchesToInsert)
        external
        onlyCoordinator
    {
        for (uint256 i = 0; i < matchesToInsert.length; i++) {
            Match storage soccerMatch = matches[champId][
                matchIds[champId].current()
            ];

            soccerMatch.start = matchesToInsert[i].start;
            soccerMatch.house = matchesToInsert[i].house;
            soccerMatch.visitor = matchesToInsert[i].visitor;

            emit MatchInserted(
                matchIds[champId].current(),
                champId,
                matchesToInsert[i].house,
                matchesToInsert[i].visitor,
                matchesToInsert[i].start
            );

            matchIds[champId].increment();
        }
    }

    function getMatch(uint256 champId, uint256 matchId)
        external
        view
        returns (Match memory)
    {
        Match memory soccerMatch = matches[champId][matchId];
        return soccerMatch;
    }

    function fullfillResults(Fullfill[] memory results)
        external
        onlyCoordinator
    {
        for (uint256 i = 0; i < results.length; i++) {
            Match storage soccerMatch = matches[results[i].champId][
                results[i].matchId
            ];

            require(!soccerMatch.resultsFullfilled, "already fullfilled");

            soccerMatch.houseGoals = results[i].house;
            soccerMatch.visitorGoals = results[i].visitor;

            soccerMatch.resultsFullfilled = true;
        }
    }

    function closeMatches(CloseMatches[] memory matchesToClose)
        external
        onlyCoordinator
    {
        for (uint256 i = 0; i < matchesToClose.length; i++) {
            Match storage soccerMatch = matches[matchesToClose[i].champId][
                matchesToClose[i].matchId
            ];
            require(soccerMatch.resultsFullfilled, "No results yet");

            soccerMatch.closed = true;
        }

        betsContract.closeMatches(matchesToClose);
    }
}
