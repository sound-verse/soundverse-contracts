// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require('fs');

async function main() {

  const LiniftyToken = await hre.ethers.getContractFactory("LiniftyToken");
  const token = await LiniftyToken.deploy(LiniftyToken, 6000000000);
  await token.deployed();
  console.log("LiniftyToken deployed to:", token.address);

  // let config = `
  // export const nftmarketaddress = "${nftMarket.address}"
  // export const nftaddress = "${nft.address}"
  // `
  // let data = JSON.stringify(config)
  // fs.writeFileSync('config.js', JSON.parse(data))
  
}