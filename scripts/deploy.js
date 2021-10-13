// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const fs = require('fs');


async function main() {
  const date = new Date().getTime + 20 * 60 * 1000;

  const SoundVerseToken = await hre.ethers.getContractFactory(
    "SoundVerseToken"
  );
  const PercentageCalculator = await hre.ethers.getContractFactory(
    "PercentageCalculator"
  );
  const Vesting = await hre.ethers.getContractFactory("Vesting");
  const token = await SoundVerseToken.deploy(SoundVerseToken, 6000000000);
  await token.deployed();

  const percentageCalculator = await PercentageCalculator.deploy();
  await percentageCalculator;

  const vest = await Vesting.deploy(token.address, date, 1000000);
  await vest.deployed;
  
  console.log("SoundVerseToken deployed to:", token.address);
  console.log("SoundVerseToken deployed to:", vest.ddress);

  // let config = `
  // export const nftmarketaddress = "${nftMarket.address}"
  // export const nftaddress = "${nft.address}"
  // `
  // let data = JSON.stringify(config)
  // fs.writeFileSync('config.js', JSON.parse(data))
}
