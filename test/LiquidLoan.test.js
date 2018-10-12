/* eslint-env node, mocha */
/* global artifacts, contract, it, assert */

const LiquidLoan = artifacts.require('LiquidLoan');

let instance;

contract('LiquidLoan', (accounts) => {
  it('Should deploy an instance of the LiquidLoan contract', () => LiquidLoan.deployed()
    .then((contractInstance) => {
      instance = contractInstance;
    }));
});
