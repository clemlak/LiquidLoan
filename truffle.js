require('dotenv').config();
const HDWalletProvider = require('truffle-hdwallet-provider');
const web3 = require('web3');

const mainnetUrl = `https://mainnet.infura.io/${process.env.INFURA}`;
const rinkebyUrl = `https://rinkeby.infura.io/${process.env.INFURA}`;

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
      gas: 4712388,
      gasPrice: web3.utils.toWei('2', 'gwei'),
    },
    rinkeby: {
      provider() {
        return new HDWalletProvider(process.env.MNEMONIC, rinkebyUrl, 0);
      },
      network_id: 4,
      gasPrice: web3.utils.toWei('100', 'gwei'),
      gas: 4712388,
    },
    live: {
      provider() {
        return new HDWalletProvider(process.env.MNEMONIC, mainnetUrl, 0);
      },
      network_id: 1,
      gasPrice: web3.utils.toWei('2', 'gwei'),
      gas: 4712388,
    },
  },
  mocha: {
    useColors: true,
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
