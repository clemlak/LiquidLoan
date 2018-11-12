# LiquidLoan

## Introduction

*Note: This project is still in progress.*

LiquidLoan is a P2P crypto lending (Proof-of-Concept) dApp built into the [Snowflake](https://github.com/NoahHydro/snowflake-dashboard) dApp store. The goal of this project is to try out the development of a dApp built on Snowflake and to give to the [Hydro](https://github.com/hydrogen-dev) team a feedback about the experience.

## How it works

This PoC dApp allows people to borrow / lend Hydro tokens. The whole concept is based on a score system to provide trust among users. All users actions (lending, borrowing or reimbursing funds) are recorded and displayed publicly.

* Users sign up to the dApp using their Snowflake ID
* All users have 4 stats: current debt, lent amount, borrowed amount, reimbursed amount
* Users can ask for a loan, specifying the requested amount, the rate, and the deadline
* Users can lend money to eachothers
