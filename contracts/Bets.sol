//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IClaimBetVerifier.sol";
import "./interfaces/IMakeBetVerifier.sol";
import "./interfaces/IBrazilianStorm.sol";
import "./interfaces/IMatches.sol";

import "./Dto.sol";

contract Bets is Dto {
    using Counters for Counters.Counter;

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
        uint16 multiplier;
    }

    struct ScoreBets {
        mapping(uint256 => ScoreBet) bets;
        Counters.Counter counter;
        uint16 multiplier;
    }

    struct GoalsBets {
        mapping(uint256 => GoalsBet) bets;
        Counters.Counter counter;
        uint16 multiplier;
    }

    struct MatchBets {
        WinnerBets winner;
        ScoreBets score;
        GoalsBets goals;
    }

    struct MatchBetsValues {
        WinnerBet[] winner;
        ScoreBet[] score;
        GoalsBet[] goals;
    }

    mapping(uint256 => mapping(uint256 => MatchBets)) private bets;

    IClaimBetVerifier private claimBetVerifier;
    IMakeBetVerifier private betVerifier;
    IBrazilianStorm private brazilianStorm;
    IMatches private matches;
    address private matchesAddress;

    constructor(
        address _betVerifier,
        address _claimBetVerifier,
        address _mainContract,
        address _matchContract
    ) {
        betVerifier = IMakeBetVerifier(_betVerifier);
        claimBetVerifier = IClaimBetVerifier(_claimBetVerifier);

        brazilianStorm = IBrazilianStorm(_mainContract);
        matches = IMatches(_matchContract);
        matchesAddress = _matchContract;
    }

    event BetInserted(
        uint256 id,
        uint256 champId,
        uint256 matchId,
        uint256 better,
        string betType
    );

    function _bet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId
    ) internal {
        bool isValidProof = betVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Match memory soccerMatch = matches.getMatch(champId, matchId);

        require(
            block.timestamp + 3600 <= soccerMatch.start,
            "To late to bet on this match"
        );

        brazilianStorm.changeBalance(input[0], input[1], input[2]);
    }

    function betWinner(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId,
        bool house
    ) external {
        _bet(a, b, c, input, champId, matchId);

        WinnerBets storage winnerBets = bets[champId][matchId].winner;

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

    function betScore(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId,
        uint8 house,
        uint8 visitor
    ) external {
        _bet(a, b, c, input, champId, matchId);

        ScoreBets storage scoreBets = bets[champId][matchId].score;

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

    function betGoals(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId,
        bool house,
        uint8 goals
    ) external {
        _bet(a, b, c, input, champId, matchId);

        GoalsBets storage goalsBets = bets[champId][matchId].goals;

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

    function claimWinnerBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) external {
        bool isValidProof = claimBetVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Match memory soccerMatch = matches.getMatch(champId, matchId);
        require(soccerMatch.closed, "Coordinator needs to close match");

        WinnerBets storage winnerBets = bets[champId][matchId].winner;
        WinnerBet storage winnerBet = winnerBets.bets[betId];

        require(!winnerBet.claimed, "Already claimed");

        require(
            winnerBet.better == input[0] &&
                winnerBet.value == input[3] &&
                winnerBets.multiplier == uint16(input[4]),
            "Invalid bet"
        );

        require(
            (winnerBet.house &&
                soccerMatch.houseGoals > soccerMatch.visitorGoals) ||
                (!winnerBet.house &&
                    soccerMatch.houseGoals < soccerMatch.visitorGoals),
            "Did not win"
        );

        winnerBet.claimed = true;

        brazilianStorm.changeBalance(input[0], input[1], input[2]);
    }

    function claimScoreBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) external {
        bool isValidProof = claimBetVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Match memory soccerMatch = matches.getMatch(champId, matchId);
        require(soccerMatch.closed, "Coordinator needs to close match");

        ScoreBets storage scoreBets = bets[champId][matchId].score;
        ScoreBet storage scoreBet = scoreBets.bets[betId];

        require(!scoreBet.claimed, "Already claimed");

        require(
            scoreBet.better == input[0] &&
                scoreBet.value == input[3] &&
                scoreBets.multiplier == uint16(input[4]),
            "Invalid bet"
        );

        require(
            scoreBet.house == soccerMatch.houseGoals &&
                scoreBet.visitor == soccerMatch.visitorGoals,
            "Did not win"
        );

        scoreBet.claimed = true;

        brazilianStorm.changeBalance(input[0], input[1], input[2]);
    }

    function claimGoalsBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) external {
        bool isValidProof = claimBetVerifier.verifyProof(a, b, c, input);
        require(isValidProof, "Invalid proof");

        Match memory soccerMatch = matches.getMatch(champId, matchId);
        require(soccerMatch.closed, "Coordinator needs to close match");

        GoalsBets storage goalsBets = bets[champId][matchId].goals;
        GoalsBet storage goalsBet = goalsBets.bets[betId];

        require(!goalsBet.claimed, "Already claimed");

        require(
            goalsBet.better == input[0] &&
                goalsBet.value == input[3] &&
                goalsBets.multiplier == uint16(input[4]),
            "Invalid bet"
        );

        require(
            (goalsBet.house && soccerMatch.houseGoals == goalsBet.goals) ||
                (goalsBet.house && soccerMatch.visitorGoals == goalsBet.goals),
            "Did not win"
        );

        goalsBet.claimed = true;

        brazilianStorm.changeBalance(input[0], input[1], input[2]);
    }

    function getMatchBets(uint256 champId, uint256 matchId)
        public
        view
        returns (MatchBetsValues memory)
    {
        Match memory soccerMatch = matches.getMatch(champId, matchId);
        require(soccerMatch.resultsFullfilled, "No results yet");

        MatchBets storage matchBets = bets[champId][matchId];

        WinnerBet[] memory winnerBets = new WinnerBet[](
            matchBets.winner.counter.current()
        );

        GoalsBet[] memory goalsBets = new GoalsBet[](
            matchBets.goals.counter.current()
        );

        ScoreBet[] memory scoreBets = new ScoreBet[](
            matchBets.score.counter.current()
        );

        for (uint256 i = 0; i < matchBets.winner.counter.current(); i++) {
            winnerBets[i] = matchBets.winner.bets[i];
        }

        for (uint256 i = 0; i < matchBets.goals.counter.current(); i++) {
            goalsBets[i] = matchBets.goals.bets[i];
        }

        for (uint256 i = 0; i < matchBets.score.counter.current(); i++) {
            scoreBets[i] = matchBets.score.bets[i];
        }

        return (MatchBetsValues(winnerBets, scoreBets, goalsBets));
    }

    function closeMatches(CloseMatches[] memory matchesToClose) external {
        require(msg.sender == matchesAddress, "only match contract");

        uint256 coordinatorFee = 0;

        for (uint256 i = 0; i < matchesToClose.length; i++) {
            MatchBets storage matchBets = bets[matchesToClose[i].champId][
                matchesToClose[i].matchId
            ];

            matchBets.winner.multiplier = matchesToClose[i].winnerMultiplier;
            matchBets.score.multiplier = matchesToClose[i].scoreMultiplier;
            matchBets.goals.multiplier = matchesToClose[i].goalsMultiplier;

            coordinatorFee += matchesToClose[i].coordinatorFee;
        }

        brazilianStorm.payCoordinator(coordinatorFee);
    }

    function getWinnerBet(
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) external view returns (WinnerBet memory) {
        WinnerBet memory winner = bets[champId][matchId].winner.bets[betId];
        return winner;
    }

    function getScoreBet(
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) external view returns (ScoreBet memory) {
        ScoreBet memory score = bets[champId][matchId].score.bets[betId];
        return score;
    }

    function getGoalsBet(
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) external view returns (GoalsBet memory) {
        GoalsBet memory goals = bets[champId][matchId].goals.bets[betId];
        return goals;
    }
}
