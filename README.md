# Brazilian Storm Sportingbet CONTRACTS <!-- omit in toc -->

Brazilian Storm Sportingbet is a platform that allows users to bet on brazilian soccer matches using zk to hide users balance and bets values.


The project is currently on [Harmony Devnet](https://explorer.ps.hmny.io/)

Brazilian Storm Sportingbet has 3 bet options so far: Winner where a user bets on who will win the match, Score where a user bets on the match score and Goal where the user bets on how many goals one specific team will score.

<!-- Brazilian Storm Sportingbet Demo Video:

https://youtu.be -->

## Table of Contents <!-- omit in toc -->

- [Project Structure](#project-structure)
  - [circuits](#circuits)
  - [contracts](#contracts)
- [Run Locally](#run-locally)
  - [Clone the Repository](#clone-the-repository)
  - [Run circuits](#run-circuits)
  - [Run contracts](#run-contracts)

## Project Structure

The project has three main folders:

- circuits
- contracts
- zkgames-ui

### circuits

The [circuits folder](/circuits/) contains all the circuits used in Brazilian Storm Sportingbet.


### contracts

The [contracts folder](/contracts/) contains all the smart contracts used in Brazilian Storm Sportingbet.


## Run Locally

### Clone the Repository

```bash
git clone https://github.com/joaopedrocyrino/brazilian-storm-sportingbet-contracts.git
```

### Run circuits

To run cicuits:

```bash
yarn circuits
```

### Run contracts

To run contracts:

```bash
yarn local
```