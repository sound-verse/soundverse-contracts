const config = require('dotenv').config()
require("@nomiclabs/hardhat-etherscan")
require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("@openzeppelin/hardhat-upgrades");
const fs = require('fs')

// When using the hardhat network, you may choose to fork Fuji or Avalanche Mainnet
// This will allow you to debug contracts using the hardhat network while keeping the current network state
// To enable forking, turn one of these booleans on, and then run your tasks/scripts using ``--network hardhat``
// For more information go to the hardhat guide
// https://hardhat.org/hardhat-network/
// https://hardhat.org/guides/mainnet-forking.html
const FORK_FUJI = false
const FORK_MAINNET = false
const forkingData = FORK_FUJI ? {
  url: 'https://api.avax-test.network/ext/bc/C/rpc',
} : FORK_MAINNET ? {
  url: 'https://api.avax.network/ext/bc/C/rpc'
} : undefined

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
  solidity: "0.8.4",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    local: {
      url: 'http://127.0.0.1:8545/ext/bc/C/rpc',
      gasPrice: "auto",
      chainId: 43112,
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
      chainId: !forkingData ? 43112 : undefined, //Only specify a chainId if we are not forking
      forking: forkingData
    },
    mumbai: {
      url: process.env.MUMBAI_URL || "",
      accounts: process.env.PRIVATE_KEY1 !== undefined ? [process.env.PRIVATE_KEY1, process.env.PRIVATE_KEY2] : [],
    },
    fuji: {
      url: process.env.FUJI_URL || "",
      gasPrice: "auto",
      chainId: 43113,
      accounts: [process.env.PRIVATE_KEY1]
    },
    avalanche: {
      url: process.env.AVALANCHE_URL || "",
      gasPrice: "auto",
      chainId: 43114,
      accounts: []
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};