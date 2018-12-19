/* eslint-env node */
/* global artifacts */

const LiquidLoan = artifacts.require('./core/LiquidLoan');
const snowflakeAddress = '0x7EdA95f86D49ac97D2142Cb3903915835160efEe';

function deployContracts(deployer) {
  deployer.deploy(LiquidLoan, snowflakeAddress);
}

module.exports = deployContracts;
