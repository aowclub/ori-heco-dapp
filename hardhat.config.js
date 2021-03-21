require("@nomiclabs/hardhat-waffle");
require('hardhat-abi-exporter');
const fs = require('fs');
require('dotenv').config();

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const INFURA_PROJECT_ID = process.env.infuraKey;
const privateKey = "";

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      blockGasLimit: 8000000,
      gas: 8000000,
      gasPrice: 1000000000,
      allowUnlimitedContractSize: true,
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${INFURA_PROJECT_ID}`,
      accounts: [`${privateKey}`],
      blockGasLimit: 8000000,
      gas: 8000000,
      gasPrice: 1000000000,
    },
    heco: {
      url: "https://http-mainnet-node.huobichain.com",
      network_id: 128,
      accounts: [`${privateKey}`],
      blockGasLimit: 19500000,
      gas: 8000000,
      gasPrice: 1000000000,
    },
    heco_test: {
      url: "https://http-testnet.hecochain.com",
      network_id: 256,
      accounts: [`${privateKey}`],
      blockGasLimit: 19500000,
      gas: 8000000,
      gasPrice: 1000000000,
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.6.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: '0.5.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
    ]
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true
  }
};
