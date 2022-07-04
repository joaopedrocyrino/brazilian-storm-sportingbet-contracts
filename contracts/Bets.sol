//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IClaimBetVerifier.sol";
import "./interfaces/IMakeBetVerifier.sol";

import "./Users.sol";

contract Bets is Users {
    using Counters for Counters.Counter;

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

    event BetInserted(
        uint256 id,
        uint256 champId,
        uint256 matchId,
        uint256 better,
        string betType
    );

    struct Match {
        string house;
        string visitor;
        uint256 start;
        uint8 houseGoals;
        uint8 visitorGoals;
        bool closed;
        bool resultsFullfilled;
    }

    struct WinnerBet {
        bool house;
        uint256 better;
        uint256 value;
        bool claimed;
    }

    struct GoalsBet {
        bool house;
        uint8 goals;
        uint256 better;
        uint256 value;
        bool claimed;
    }

    struct ScoreBet {
        uint8 house;
        uint8 visitor;
        uint256 better;
        uint256 value;
        bool claimed;
    }

    struct WinnerBets {
        mapping(uint256 => WinnerBet) bets;
        Counters.Counter counter;
        uint256 totalLostValue;
        uint16 multiplier;
    }

    struct ScoreBets {
        mapping(uint256 => ScoreBet) bets;
        Counters.Counter counter;
        uint256 totalLostValue;
        uint16 multiplier;
    }

    struct GoalsBets {
        mapping(uint256 => GoalsBet) bets;
        Counters.Counter counter;
        uint256 totalLostValue;
        uint16 multiplier;
    }

    struct MatchBets {
        WinnerBets winner;
        ScoreBets score;
        GoalsBets goals;
    }

    struct Championship {
        string name;
        uint16 season;
        string country;
        bool closed;
        mapping(uint256 => Match) matches;
        mapping(uint256 => MatchBets) matchBets;
        Counters.Counter matchIds;
        uint256 openMatchIndex;
    }

    struct ChampionshipFields {
        string name;
        uint16 season;
        string country;
        bool closed;
        uint256 openMatchIndex;
    }

    struct CloseMatches {
        uint256 champId;
        uint256 matchId;
        uint256 winnerTotalLostValue;
        uint16 winnerMultiplier;
        uint256 scoreTotalLostValue;
        uint16 scoreMultiplier;
        uint256 goalsTotalLostValue;
        uint16 goalsMultiplier;
    }

    struct Fullfill {
        uint8 house;
        uint8 visitor;
        uint256 matchId;
        uint256 champId;
    }

    struct BetValues {
        uint256 matchId;
        uint256 champId;
        ScoreBet[] scoreBets;
        WinnerBet[] winnerBets;
        GoalsBet[] goalsBets;
        uint8 house;
        uint8 visitor;
    }

    mapping(uint256 => Championship) internal championships;
    Counters.Counter public champIds;
    uint256 public openChampionshipIndex;

    IClaimBetVerifier private claimBetVerifier;
    IMakeBetVerifier private betVerifier;

    constructor(
        address _createUserVerifier,
        address _depositVerifier,
        address _withdrawnVerifier,
        address _betVerifier,
        address _claimBetVerifier
    ) Users(_createUserVerifier, _depositVerifier, _withdrawnVerifier) {
        betVerifier = IMakeBetVerifier(_betVerifier);
        claimBetVerifier = IClaimBetVerifier(_claimBetVerifier);
    }

    /// @dev Coordinator functions

    // function _insertChampionships(ChampionshipFields[] memory champs) internal {
    //     for (uint256 i = 0; i < champs.length; i++) {
    //         Championship storage champ = championships[champIds.current()];

    //         champ.name = champs[i].name;
    //         champ.season = champs[i].season;
    //         champ.country = champs[i].country;

    //         emit ChampionshipInserted(
    //             champIds.current(),
    //             champs[i].name,
    //             champs[i].season,
    //             champs[i].country
    //         );

    //         champIds.increment();
    //     }
    // }

    // function _insertMatches(uint256 champId, Match[] memory matches) internal {
    //     Championship storage champ = championships[champId];

    //     for (uint256 i = 0; i < matches.length; i++) {
    //         champ.matches[champ.matchIds.current()].start = matches[i].start;
    //         champ.matches[champ.matchIds.current()].house = matches[i].house;
    //         champ.matches[champ.matchIds.current()].visitor = matches[i]
    //             .visitor;

    //         emit MatchInserted(
    //             champ.matchIds.current(),
    //             champId,
    //             matches[i].house,
    //             matches[i].visitor
    //         );

    //         champ.matchIds.increment();
    //     }
    // }

    // function _closeChampionship(uint256 champId) internal {
    //     Championship storage champ = championships[champId];
    //     champ.closed = true;

    //     if (champId <= openChampionshipIndex) {
    //         openChampionshipIndex = champId + 1;
    //     }
    // }

    // function _closeMatches(CloseMatches[] memory matchesToClose) internal {
    //     for (uint256 i = 0; i < matchesToClose.length; i++) {
    //         Championship storage champ = championships[
    //             matchesToClose[i].champId
    //         ];
    //         Match storage soccerMatch = champ.matches[
    //             matchesToClose[i].matchId
    //         ];
    //         require(soccerMatch.resultsFullfilled, "No results yet");

    //         MatchBets storage bets = champ.matchBets[matchesToClose[i].matchId];

    //         bets.winner.totalLostValue = matchesToClose[i].winnerTotalLostValue;
    //         bets.winner.multiplier = matchesToClose[i].winnerMultiplier;

    //         bets.score.totalLostValue = matchesToClose[i].scoreTotalLostValue;
    //         bets.score.multiplier = matchesToClose[i].scoreMultiplier;

    //         bets.goals.totalLostValue = matchesToClose[i].goalsTotalLostValue;
    //         bets.goals.multiplier = matchesToClose[i].goalsMultiplier;

    //         soccerMatch.closed = true;

    //         if (matchesToClose[i].matchId <= champ.openMatchIndex) {
    //             champ.openMatchIndex = matchesToClose[i].matchId + 1;
    //         }
    //     }
    // }

    // function _fullfillResults(Fullfill[] memory results)
    //     internal
    //     returns (BetValues[] memory)
    // {
        // BetValues[] memory betValues = new BetValues[](results.length);

        // for (uint256 i = 0; i < results.length; i++) {
        //     Championship storage champ = championships[results[i].champId];
        //     Match storage soccerMatch = champ.matches[results[i].matchId];

        //     require(!soccerMatch.resultsFullfilled, "already fullfilled");

        //     soccerMatch.houseGoals = results[i].house;
        //     soccerMatch.visitorGoals = results[i].visitor;

        //     soccerMatch.resultsFullfilled = true;

        //     MatchBets storage bets = champ.matchBets[results[i].matchId];

        //     WinnerBet[] memory winnerBets = new WinnerBet[](
        //         bets.winner.counter.current()
        //     );

        //     GoalsBet[] memory goalsBets = new GoalsBet[](
        //         bets.goals.counter.current()
        //     );

        //     ScoreBet[] memory scoreBets = new ScoreBet[](
        //         bets.score.counter.current()
        //     );

        //     betValues[i] = BetValues(
        //         results[i].matchId,
        //         results[i].champId,
        //         scoreBets,
        //         winnerBets,
        //         goalsBets,
        //         results[i].house,
        //         results[i].visitor
        //     );
        // }

        // return betValues;
    // }

    /// @dev bet insert functions

    function _insertBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId
    ) private {
        bool isValidProof = betVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Match memory soccerMatch = championships[champId].matches[matchId];

        require(
            block.timestamp <= soccerMatch.start,
            "To late to bet on this match"
        );

        _changeBalance(input[0], input[1], input[2]);
    }

    function _insertWinnerBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId,
        bool house
    ) internal {
        _insertBet(a, b, c, input, champId, matchId);

        WinnerBets storage winnerBets = championships[champId]
            .matchBets[matchId]
            .winner;

        winnerBets.bets[winnerBets.counter.current()] = WinnerBet(
            house,
            input[0],
            input[3],
            false
        );

        emit BetInserted(
            winnerBets.counter.current(),
            champId,
            matchId,
            input[0],
            "winner"
        );

        winnerBets.counter.increment();
    }

    function _insertScoreBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId,
        uint8 house,
        uint8 visitor
    ) internal {
        _insertBet(a, b, c, input, champId, matchId);

        ScoreBets storage scoreBets = championships[champId]
            .matchBets[matchId]
            .score;

        scoreBets.bets[scoreBets.counter.current()] = ScoreBet(
            house,
            visitor,
            input[0],
            input[3],
            false
        );

        emit BetInserted(
            scoreBets.counter.current(),
            champId,
            matchId,
            input[0],
            "score"
        );

        scoreBets.counter.increment();
    }

    function _insertGoalsBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId,
        bool house,
        uint8 goals
    ) internal {
        _insertBet(a, b, c, input, champId, matchId);

        GoalsBets storage goalsBets = championships[champId]
            .matchBets[matchId]
            .goals;

        goalsBets.bets[goalsBets.counter.current()] = GoalsBet(
            house,
            goals,
            input[0],
            input[3],
            false
        );

        emit BetInserted(
            goalsBets.counter.current(),
            champId,
            matchId,
            input[0],
            "goals"
        );

        goalsBets.counter.increment();
    }

    /// @dev claim bet functions

    function _claimWinnerBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) internal {
        bool isValidProof = claimBetVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Championship storage champ = championships[champId];
        Match memory soccerMatch = champ.matches[matchId];
        WinnerBets storage bets = champ.matchBets[matchId].winner;
        WinnerBet storage bet = bets.bets[betId];

        require(soccerMatch.closed, "Coordinator needs to close match");
        require(!bet.claimed, "Already claimed");

        require(
            bet.better == input[0] &&
                bet.value == input[3] &&
                bets.multiplier == uint16(input[4]),
            "Invalid bet"
        );

        require(
            (bet.house && soccerMatch.houseGoals > soccerMatch.visitorGoals) ||
                (!bet.house &&
                    soccerMatch.houseGoals < soccerMatch.visitorGoals),
            "Did not win"
        );

        bet.claimed = true;

        _changeBalance(input[0], input[1], input[2]);
    }

    function _claimScoreBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) internal {
        bool isValidProof = claimBetVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Championship storage champ = championships[champId];
        Match memory soccerMatch = champ.matches[matchId];
        ScoreBets storage bets = champ.matchBets[matchId].score;
        ScoreBet storage bet = bets.bets[betId];

        require(soccerMatch.closed, "Coordinator needs to close match");
        require(!bet.claimed, "Already claimed");

        require(
            bet.better == input[0] &&
                bet.value == input[3] &&
                bets.multiplier == uint16(input[4]),
            "Invalid bet"
        );

        require(
            bet.house == soccerMatch.houseGoals &&
                bet.visitor == soccerMatch.visitorGoals,
            "Did not win"
        );

        bet.claimed = true;

        _changeBalance(input[0], input[1], input[2]);
    }

    function _claimGoalsBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) internal {
        bool isValidProof = claimBetVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Championship storage champ = championships[champId];
        Match memory soccerMatch = champ.matches[matchId];
        GoalsBets storage bets = champ.matchBets[matchId].goals;
        GoalsBet storage bet = bets.bets[betId];

        require(soccerMatch.closed, "Coordinator needs to close match");
        require(!bet.claimed, "Already claimed");

        require(
            bet.better == input[0] &&
                bet.value == input[3] &&
                bets.multiplier == uint16(input[4]),
            "Invalid bet"
        );

        require(
            (bet.house && soccerMatch.houseGoals == bet.goals) ||
                (!bet.house && soccerMatch.visitorGoals == bet.goals),
            "Did not win"
        );

        bet.claimed = true;

        _changeBalance(input[0], input[1], input[2]);
    }

    /// @dev query data functions

    function _getChampionships()
        internal
        view
        returns (ChampionshipFields[] memory)
    {
        ChampionshipFields[] memory champs = new ChampionshipFields[](
            champIds.current()
        );

        for (uint256 i = openChampionshipIndex; i < champIds.current(); i++) {
            Championship storage champ = championships[i];
            champs[i - openChampionshipIndex] = ChampionshipFields(
                champ.name,
                champ.season,
                champ.country,
                champ.closed,
                champ.openMatchIndex
            );
        }

        return champs;
    }

    function _getMatches(uint256 champId)
        internal
        view
        returns (Match[] memory)
    {
        Championship storage champ = championships[champId];

        Match[] memory matches = new Match[](champ.matchIds.current());

        for (
            uint256 i = champ.openMatchIndex;
            i < champ.matchIds.current();
            i++
        ) {
            Match memory soccerMatch = champ.matches[i];
            matches[i - champ.openMatchIndex] = soccerMatch;
        }

        return matches;
    }
}
