//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IClaimBetVerifier.sol";

contract Bets {
    using Counters for Counters.Counter;

    event MatchCreated(
        uint256 id,
        uint16 season,
        uint8 round,
        string house,
        string visitor
    );
    event BetCreated(
        uint256 id,
        uint256 matchId,
        uint256 better,
        string betType
    );

    struct Bet {
        uint256 id;
        uint256 better;
        uint256 value;
        bool won;
        bool claimed;
    }

    struct WinnerBet {
        bool houseWins;
        Bet bet;
    }

    struct GoalsBet {
        bool house;
        uint8 goals;
        Bet bet;
    }

    struct ScoreBet {
        uint8 house;
        uint8 visitor;
        Bet bet;
    }

    struct BetValues {
        uint256 lostBetsValue;
        uint16 returnMultiplier;
    }

    struct WinnerBets {
        /// @dev bet id => Bet
        mapping(uint256 => WinnerBet) bets;
        /// @dev counter of bets
        Counters.Counter counter;
        /// @dev values of this bet type
        BetValues betValues;
    }

    struct ScoreBets {
        /// @dev bet id => Bet
        mapping(uint256 => ScoreBet) bets;
        /// @dev counter of bets
        Counters.Counter counter;
        /// @dev values of this bet type
        BetValues betValues;
    }

    struct GoalsBets {
        /// @dev bet id => Bet
        mapping(uint256 => GoalsBet) bets;
        /// @dev counter of bets
        Counters.Counter counter;
        /// @dev values of this bet type
        BetValues betValues;
    }

    struct MatchBets {
        WinnerBets winner;
        ScoreBets score;
        GoalsBets goals;
    }

    struct Match {
        uint256 id;
        /// @dev round of the season (up to 38)
        uint8 round;
        /// @dev season (year)
        uint16 season;
        /// @dev name of house team
        string house;
        /// @dev name of visitor team
        string visitor;
        /// @dev the limit time a user can bet on this match
        uint256 limitTime;
        /// @dev true if values were posted by the coordinator
        bool closed;
        MatchBets bets;
    }

    /// @dev match id => Match
    mapping(uint256 => Match) internal matches;

    Counters.Counter public _matchIds;

    IClaimBetVerifier private claimBetVerifier;

    constructor(address _claimBetVerifier) {
        claimBetVerifier = IClaimBetVerifier(_claimBetVerifier);
    }

    function claimBet(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[5] memory input,
        Bet storage bet,
        uint16 betMultiplier
    ) internal {
        bool isValidProof = claimBetVerifier.verifyProof(a, b, c, input);

        require(isValidProof, "Invalid proof");

        require(
            bet.better == input[0] &&
                bet.value == input[3] &&
                betMultiplier == uint16(input[4]),
            "Invalid bet"
        );

        require(!bet.claimed, "Already claimed");

        require(bet.won, "Did not win");

        bet.claimed = true;
    }
}
