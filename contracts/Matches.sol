//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IBet.sol";

import "./Dto.sol";

contract Matches is Dto {
    using Counters for Counters.Counter;

    struct Championship {
        uint256 id;
        string name;
        uint16 season;
        string country;
        bool closed;
        uint256 openMatchIndex;
    }

    struct Fullfill {
        uint8 house;
        uint8 visitor;
        uint256 matchId;
        uint256 champId;
    }

    mapping(uint256 => Championship) public championships;
    Counters.Counter public champIds;

    uint256 public openChampionshipIndex;

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
        string visitor
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
            Championship storage champ = championships[champIds.current()];

            champ.id = champIds.current();
            champ.name = champs[i].name;
            champ.season = champs[i].season;
            champ.country = champs[i].country;

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

            soccerMatch.id = matchIds[champId].current();
            soccerMatch.start = matchesToInsert[i].start;
            soccerMatch.house = matchesToInsert[i].house;
            soccerMatch.visitor = matchesToInsert[i].visitor;

            emit MatchInserted(
                matchIds[champId].current(),
                champId,
                matchesToInsert[i].house,
                matchesToInsert[i].visitor
            );

            matchIds[champId].increment();
        }
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

    function getMatch(uint256 champId, uint256 matchId)
        external
        view
        returns (Match memory)
    {
        Match memory soccerMatch = matches[champId][matchId];
        return soccerMatch;
    }

    function closeChampionship(uint256 champId) external onlyCoordinator {
        Championship storage champ = championships[champId];
        champ.closed = true;

        if (champId <= openChampionshipIndex) {
            openChampionshipIndex = champId + 1;
        }
    }

    function closeMatches(CloseMatches[] memory matchesToClose)
        external
        onlyCoordinator
    {
        for (uint256 i = 0; i < matchesToClose.length; i++) {
            Championship storage champ = championships[
                matchesToClose[i].champId
            ];
            Match storage soccerMatch = matches[matchesToClose[i].champId][
                matchesToClose[i].matchId
            ];
            require(soccerMatch.resultsFullfilled, "No results yet");

            soccerMatch.closed = true;

            if (matchesToClose[i].matchId <= champ.openMatchIndex) {
                champ.openMatchIndex = matchesToClose[i].matchId + 1;
            }
        }

        betsContract.closeMatches(matchesToClose);
    }

    function getChampionships () external view returns (Championship[] memory) {
        Championship[] memory champs = new Championship[](champIds.current() - openChampionshipIndex);

        for (uint256 i = openChampionshipIndex; i < champIds.current(); i++) {
            champs[i - openChampionshipIndex] = championships[i];
        }

        return champs;
    }

    function getMatches (uint256 champId) external view returns (Match[] memory) {
        Championship memory champ = championships[champId];

        Match[] memory m = new Match[](matchIds[champId].current() - champ.openMatchIndex);

        for (uint256 i = champ.openMatchIndex; i < matchIds[champId].current(); i++) {
            m[i - champ.openMatchIndex] = matches[champId][i];
        }

        return m;
    }
}
