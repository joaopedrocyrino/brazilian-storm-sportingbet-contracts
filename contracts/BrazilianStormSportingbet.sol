//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./Users.sol";
import "./Bets.sol";

import "./interfaces/IMakeBetVerifier.sol";
import "./interfaces/IClaimBetVerifier.sol";

contract BrazilianStormSportingbet is Users, Bets {
    using Counters for Counters.Counter;

    address private coordinator;
    uint8[32][2] public coordinatorPubKey;

    IMakeBetVerifier private betVerifier;

    constructor(
        address _createUserVerifier,
        address _depositVerifier,
        address _withdrawnVerifier,
        address _betVerifier,
        address _claimBetVerifier,
        uint8[32][2] memory _coordinatorPubKey
    )
        Users(_createUserVerifier, _depositVerifier, _withdrawnVerifier)
        Bets(_claimBetVerifier)
    {
        betVerifier = IMakeBetVerifier(_betVerifier);

        coordinator = msg.sender;
        coordinatorPubKey = _coordinatorPubKey;
    }

    modifier onlyCoordinator() {
        require(msg.sender == coordinator, "Only coordinator allowed");
        _;
    }

    function createMatch(
        uint8 round,
        uint16 season,
        string memory house,
        string memory visitor,
        uint256 limitTime
    ) external onlyCoordinator {
        Match storage newMatch = matches[_matchIds.current()];

        newMatch.id = _matchIds.current();
        newMatch.season = season;
        newMatch.round = round;
        newMatch.house = house;
        newMatch.visitor = visitor;
        newMatch.limitTime = limitTime;

        emit MatchCreated(_matchIds.current(), season, round, house, visitor);

        _matchIds.increment();
    }

    function betWinner(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 matchId,
        bool houseWins
    ) external {
        bool isValidProof = betVerifier.verifyProof(a, b, c, input);

        require(isValidProof, "Invalid proof");

        changeBalance(input[0], input[1], input[2]);

        WinnerBets storage matchWinnerBets = matches[matchId].bets.winner;

        WinnerBet storage bet = matchWinnerBets.bets[
            matchWinnerBets.counter.current()
        ];

        bet.houseWins = houseWins;

        bet.bet.id = matchWinnerBets.counter.current();
        bet.bet.better = input[0];
        bet.bet.value = input[3];

        matchWinnerBets.counter.increment();
    }

    function betGoals(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 matchId,
        bool house,
        uint8 goals
    ) external {
        bool isValidProof = betVerifier.verifyProof(a, b, c, input);

        require(isValidProof, "Invalid proof");

        changeBalance(input[0], input[1], input[2]);

        GoalsBets storage matchGoalsBets = matches[matchId].bets.goals;

        GoalsBet storage bet = matchGoalsBets.bets[
            matchGoalsBets.counter.current()
        ];

        bet.house = house;
        bet.goals = goals;

        bet.bet.id = matchGoalsBets.counter.current();
        bet.bet.better = input[0];
        bet.bet.value = input[3];

        matchGoalsBets.counter.increment();
    }

    function betScore(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 matchId,
        uint8 house,
        uint8 visitor
    ) external {
        bool isValidProof = betVerifier.verifyProof(a, b, c, input);

        require(isValidProof, "Invalid proof");

        changeBalance(input[0], input[1], input[2]);

        ScoreBets storage matchScoreBets = matches[matchId].bets.score;

        ScoreBet storage bet = matchScoreBets.bets[
            matchScoreBets.counter.current()
        ];

        bet.house = house;
        bet.visitor = visitor;

        bet.bet.id = matchScoreBets.counter.current();
        bet.bet.better = input[0];
        bet.bet.value = input[3];

        matchScoreBets.counter.increment();
    }

    function getAllMatchBets(uint256 matchId)
        external
        view
        onlyCoordinator
        returns (
            WinnerBet[] memory,
            GoalsBet[] memory,
            ScoreBet[] memory
        )
    {
        MatchBets storage matchBets = matches[matchId].bets;

        WinnerBet[] memory winner = new WinnerBet[](
            matchBets.winner.counter.current()
        );

        for (uint256 i = 0; i < matchBets.winner.counter.current(); i++) {
            winner[i] = matchBets.winner.bets[i];
        }

        GoalsBet[] memory goals = new GoalsBet[](
            matchBets.goals.counter.current()
        );

        for (uint256 i = 0; i < matchBets.goals.counter.current(); i++) {
            goals[i] = matchBets.goals.bets[i];
        }

        ScoreBet[] memory score = new ScoreBet[](
            matchBets.score.counter.current()
        );

        for (uint256 i = 0; i < matchBets.score.counter.current(); i++) {
            score[i] = matchBets.score.bets[i];
        }

        return (winner, goals, score);
    }

    function closeMatchBets(
        uint256 matchId,
        uint256 scoreLostValue,
        uint256 goalsLostValue,
        uint256 winnerLostValue,
        uint16 scoreMultiplier,
        uint16 goalsMultiplier,
        uint16 winnerMultiplier
    ) external payable onlyCoordinator {
        Match storage soccerMatch = matches[matchId];

        uint256 winnerValue = (winnerLostValue * 90) / 100;
        uint256 scoreValue = (scoreLostValue * 90) / 100;
        uint256 goalsValue = (goalsLostValue * 90) / 100;

        uint256 coordinatorFee = (winnerLostValue - winnerValue) +
            (scoreLostValue - scoreValue) +
            (goalsLostValue - goalsValue);

        soccerMatch.bets.winner.betValues.lostBetsValue = winnerValue;
        soccerMatch.bets.winner.betValues.returnMultiplier = winnerMultiplier;

        soccerMatch.bets.goals.betValues.lostBetsValue = goalsValue;
        soccerMatch.bets.goals.betValues.returnMultiplier = goalsMultiplier;

        soccerMatch.bets.score.betValues.lostBetsValue = scoreValue;
        soccerMatch.bets.score.betValues.returnMultiplier = scoreMultiplier;

        soccerMatch.closed = true;

        payable(coordinator).transfer(coordinatorFee);
    }

    function claimBetWinner(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 matchId,
        uint256 betId
    ) external {
        WinnerBets storage bets = matches[matchId].bets.winner;

        claimBet(
            a,
            b,
            c,
            input,
            bets.bets[betId].bet,
            bets.betValues.returnMultiplier
        );

        changeBalance(input[0], input[1], input[2]);
    }

    function claimBetScore(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 matchId,
        uint256 betId
    ) external {
        ScoreBets storage bets = matches[matchId].bets.score;

        claimBet(
            a,
            b,
            c,
            input,
            bets.bets[betId].bet,
            bets.betValues.returnMultiplier
        );

        changeBalance(input[0], input[1], input[2]);
    }

    function claimBetGoals(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 matchId,
        uint256 betId
    ) external {
        GoalsBets storage bets = matches[matchId].bets.goals;

        claimBet(
            a,
            b,
            c,
            input,
            bets.bets[betId].bet,
            bets.betValues.returnMultiplier
        );

        changeBalance(input[0], input[1], input[2]);
    }

    function fullfillMatchResult(
        uint256 matchId,
        uint8 house,
        uint8 visitor
    )
        external
        onlyCoordinator
        returns (
            WinnerBet[] memory,
            GoalsBet[] memory,
            ScoreBet[] memory
        )
    {
        bool houseWins = house > visitor;

        MatchBets storage matchBets = matches[matchId].bets;

        WinnerBet[] memory winner = new WinnerBet[](
            matchBets.winner.counter.current()
        );

        for (uint256 i = 0; i < matchBets.winner.counter.current(); i++) {
            matchBets.winner.bets[i].bet.won =
                matchBets.winner.bets[i].houseWins == houseWins;
            winner[i] = matchBets.winner.bets[i];
        }

        GoalsBet[] memory goals = new GoalsBet[](
            matchBets.goals.counter.current()
        );

        for (uint256 i = 0; i < matchBets.goals.counter.current(); i++) {
            if (matchBets.goals.bets[i].house) {
                matchBets.goals.bets[i].bet.won =
                    matchBets.goals.bets[i].goals == house;
            } else {
                matchBets.goals.bets[i].bet.won =
                    matchBets.goals.bets[i].goals == visitor;
            }
            goals[i] = matchBets.goals.bets[i];
        }

        ScoreBet[] memory score = new ScoreBet[](
            matchBets.score.counter.current()
        );

        for (uint256 i = 0; i < matchBets.score.counter.current(); i++) {
            matchBets.score.bets[i].bet.won =
                matchBets.score.bets[i].house == house &&
                matchBets.score.bets[i].visitor == visitor;
            score[i] = matchBets.score.bets[i];
        }

        return (winner, goals, score);
    }
}
