/* eslint-env node */
/* global artifacts */

const LiquidLoan = artifacts.require('./core/LiquidLoan');
const snowflakeAddress = '0x03713e8a046bb4beefb03e74a74ed2236ee7b8cb';

function deployContracts(deployer) {
  deployer.deploy(LiquidLoan, snowflakeAddress);
}

module.exports = deployContracts;
