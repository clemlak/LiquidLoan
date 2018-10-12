/* eslint-env node */
/* global artifacts */

const LiquidLoan = artifacts.require('LiquidLoan');

function deployContracts(deployer) {
  deployer.deploy(LiquidLoan);
}

module.exports = deployContracts;
