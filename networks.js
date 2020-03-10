const HDWalletProvider = require('@truffle/hdwallet-provider');

require('dotenv').config();

const mnemonic = {
  // PROXY
  // ropsten: `${process.env.ROPSTEN_PROXY_MNEMONIC}`.replace(/_/g, ' '),
  // mainnet: `${process.env.MAINNET_PROXY_MNEMONIC}`.replace(/_/g, ' '),

  // OWNER
  ropsten: `${process.env.ROPSTEN_OWNER_MNEMONIC}`.replace(/_/g, ' '),
  mainnet: `${process.env.MAINNET_OWNER_MNEMONIC}`.replace(/_/g, ' '),
};

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 6000000,
      gasPrice: 1e9,
      networkId: '*',
    },
    kovan: {
      provider: () => new HDWalletProvider(
        mnemonic.kovan, `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`
      ),
      networkId: 42,
      gasPrice: 10e9
    },
    ropsten: {
      provider: () => new HDWalletProvider(
        mnemonic.ropsten, `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`
      ),
      networkId: 3,
      gasPrice: 10e9
    }
  },
};
