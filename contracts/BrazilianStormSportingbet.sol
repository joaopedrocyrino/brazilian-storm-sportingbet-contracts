//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./Bets.sol";

contract BrazilianStormSportingbet is Bets {
    using Counters for Counters.Counter;

    address private coordinator;
    uint8[32][2] public coordinatorPubKey;

    constructor(
        address _createUserVerifier,
        address _depositVerifier,
        address _withdrawnVerifier,
        address _betVerifier,
        address _claimBetVerifier,
        uint8[32][2] memory _coordinatorPubKey
    )
        Bets(
            _betVerifier,
            _claimBetVerifier,
            _createUserVerifier,
            _depositVerifier,
            _withdrawnVerifier
        )
    {
        coordinator = msg.sender;
        coordinatorPubKey = _coordinatorPubKey;
    }

    modifier onlyCoordinator() {
        require(msg.sender == coordinator, "Only coordinator allowed");
        _;
    }

    /// @dev coordinator functions

    function insertChampionships(ChampionshipFields[] memory champs)
        external
        onlyCoordinator
    {
         for (uint256 i = 0; i < champs.length; i++) {
            Championship storage champ = championships[champIds.current()];

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

    function insertMatches(uint256 champId, Match[] memory matches)
        external
        onlyCoordinator
    {
        Championship storage champ = championships[champId];

        for (uint256 i = 0; i < matches.length; i++) {
            champ.matches[champ.matchIds.current()].start = matches[i].start;
            champ.matches[champ.matchIds.current()].house = matches[i].house;
            champ.matches[champ.matchIds.current()].visitor = matches[i]
                .visitor;

            emit MatchInserted(
                champ.matchIds.current(),
                champId,
                matches[i].house,
                matches[i].visitor
            );

            champ.matchIds.increment();
        }
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
            Match storage soccerMatch = champ.matches[
                matchesToClose[i].matchId
            ];
            require(soccerMatch.resultsFullfilled, "No results yet");

            MatchBets storage bets = champ.matchBets[matchesToClose[i].matchId];

            bets.winner.totalLostValue = matchesToClose[i].winnerTotalLostValue;
            bets.winner.multiplier = matchesToClose[i].winnerMultiplier;

            bets.score.totalLostValue = matchesToClose[i].scoreTotalLostValue;
            bets.score.multiplier = matchesToClose[i].scoreMultiplier;

            bets.goals.totalLostValue = matchesToClose[i].goalsTotalLostValue;
            bets.goals.multiplier = matchesToClose[i].goalsMultiplier;

            soccerMatch.closed = true;

            if (matchesToClose[i].matchId <= champ.openMatchIndex) {
                champ.openMatchIndex = matchesToClose[i].matchId + 1;
            }
        }
    }

    function fullfillResults(Fullfill[] memory results)
        external
        onlyCoordinator
        returns (BetValues[] memory)
    {
        BetValues[] memory betValues = new BetValues[](results.length);

        for (uint256 i = 0; i < results.length; i++) {
            Championship storage champ = championships[results[i].champId];
            Match storage soccerMatch = champ.matches[results[i].matchId];

            require(!soccerMatch.resultsFullfilled, "already fullfilled");

            soccerMatch.houseGoals = results[i].house;
            soccerMatch.visitorGoals = results[i].visitor;

            soccerMatch.resultsFullfilled = true;

            MatchBets storage bets = champ.matchBets[results[i].matchId];

            WinnerBet[] memory winnerBets = new WinnerBet[](
                bets.winner.counter.current()
            );

            GoalsBet[] memory goalsBets = new GoalsBet[](
                bets.goals.counter.current()
            );

            ScoreBet[] memory scoreBets = new ScoreBet[](
                bets.score.counter.current()
            );

            betValues[i] = BetValues(
                results[i].matchId,
                results[i].champId,
                scoreBets,
                winnerBets,
                goalsBets,
                results[i].house,
                results[i].visitor
            );
        }

        return betValues;
    }

    /// @dev user functions 

    function createUser (
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input,
        uint8[32][2] memory pubKey
    ) external {
        _createUser(a, b, c, input, pubKey);
    }

    /// @dev bet functions

    function betWinner(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input,
        uint256 champId,
        uint256 matchId,
        bool house
    ) external {
        _insertWinnerBet(a, b, c, input, champId, matchId, house);
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
        _insertScoreBet(a, b, c, input, champId, matchId, house, visitor);
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
        _insertGoalsBet(a, b, c, input, champId, matchId, house, goals);
    }

    /// @dev claim bet functions

    function claimWinnerBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        uint256 champId,
        uint256 matchId,
        uint256 betId
    ) external {
        _claimWinnerBet(a, b, c, input, champId, matchId, betId);
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
        _claimGoalsBet(a, b, c, input, champId, matchId, betId);
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
        _claimScoreBet(a, b, c, input, champId, matchId, betId);
    }

    /// @dev query data functions

    function getChampionships()
        external
        view
        returns (ChampionshipFields[] memory)
    {
        ChampionshipFields[] memory champs = _getChampionships();

        return champs;
    }

    function getMatches(uint256 champId)
        external
        view
        returns (Match[] memory)
    {
        Match[] memory matches = _getMatches(champId);

        return matches;
    }
}
