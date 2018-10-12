# LiquidLoan

## Introduction

*Note: This project is still in progress.*

LiquidLoan is a Proof-of-Concept dApp built into the [Snowflake](https://github.com/NoahHydro/snowflake-dashboard) dApp store. The goal of this project is to try out the development of a dApp built on Snowflake and to provide the Hydro team a feedback about the experience.

## How it works

This PoC dApp allows people to borrow / lend Hydro tokens. The whole concept is based on a score system to provide trust among users. The higher a score is, the more trustable the person is.

* Users sign up to the dApp using their Snowflake ID
* A score is associated to each Snowflake ID, this score is permanent and will not reset, even if the user signs out and signs up again
* Score starts from 0 to "infinite"
* Everyone starts with a score of 10 000
* If you lend money, you'll receive 1 point per token you've lent
* If you borrow money, you'll receive 1 point per token you've reimbursed
* Being late / NOT reimbursing a loan will cost you A LOT of points
* Anyone can "ask" for a loan, their "request" (amount, rate and time frame) will be displayed along with their score
* Anyone can see the open requests and lend funds to anybody
* The more higher the score your score is, the more likely you will be to get your request accepted

Possible future features:
* The rate will depend on the user score
* Sign up fee to use
* Include a collateral
* Lending funds go to a "pool"
