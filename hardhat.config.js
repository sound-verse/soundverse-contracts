const config = require('dotenv').config()
require("@nomiclabs/hardhat-etherscan")
require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("@openzeppelin/hardhat-upgrades");
require('hardhat-contract-sizer');
const fs = require('fs')

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

if(config.error){
  throw config.error
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {      
    local: {
      url: 'http://127.0.0.1:8545/ext/bc/C/rpc',
      gasPrice: "auto",
      chainId: 31337,
      accounts: [
        "0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027",
        "0x7b4198529994b0dc604278c99d153cfd069d594753d471171a1d102a10438e07",
        "0x15614556be13730e9e8d6eacc1603143e7b96987429df8726384c2ec4502ef6e",
        "0x31b571bf6894a248831ff937bb49f7754509fe93bbd2517c9c73c4144c0e97dc",
        "0x6934bef917e01692b789da754a0eae31a8536eb465e7bff752ea291dad88c675",
        "0xe700bdbdbc279b808b1ec45f8c2370e4616d3a02c336e68d85d4668e08f53cff",
        "0xbbc2865b76ba28016bc2255c7504d000e046ae01934b04c694592a6276988630",
        "0xcdbfd34f687ced8c6968854f8a99ae47712c4f4183b78dcc4a903d1bfe8cbf60",
        "0x86f78c5416151fe3546dece84fda4b4b1e36089f2dbc48496faf3a950f16157c",
        "0x750839e9dbbd2a0910efe40f50b2f3b2f2f59f5580bb4b83bd8c1201cf9a010a"
      ]
    },
    hardhat: {
      gasPrice: "auto",
      chainId: 31337
    },
    mumbai: {
      chainId: 80001,
      gasMultiplier: 10,
      gas: 8000000,
      url: process.env.MUMBAI_URL || "",
      // url: "https://rpc-mumbai.maticvigil.com/v1/14f307d73c91cd84b80ce7c71643bfde9b9c92ea",
      accounts: [process.env.PRIVATE_KEY2]
    },
    fuji: {
      chainId: 43113,
      gasPrice: "auto",
      url: process.env.FUJI_URL || "",
      accounts: [process.env.PRIVATE_KEY1]
    },
    rinkeby: {
      chainId: 4,
      gasPrice: "auto",
      url: "https://rinkeby.infura.io/v3/18ba14d06a5b4798ac4bda603571cc17",
      accounts: [process.env.PRIVATE_KEY1]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};