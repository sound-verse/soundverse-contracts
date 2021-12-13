const hre = require("hardhat");
const fs = require('fs');

async function main() {

  console.log("Deploying ERC20 SoundVerse Token contract")
  const SoundVerseToken = await hre.ethers.getContractFactory("SoundVerseToken");
  const token = await SoundVerseToken.deploy();
  await token.deployed();
  console.log("SoundVerseToken deployed to:", token.address);

  const PercentageUtils = await hre.ethers.getContractFactory("PercentageUtils");
  const utils = await PercentageUtils.deploy();
  await utils.deployed();

  console.log('Deploying SoundVerse vesting contract');
  const Vesting = await hre.ethers.getContractFactory('Vesting');
  const vest = await Vesting.deploy(token.address, utils.address, [
    1000000,
    1000000,
    1000000,
    1000000,
    1000000,
    1000000,
  ]);
  await vest.deployed();
  console.log('SoundVerse vesting contract deployed to:', vest.address);

  console.log("Deploying NFT Market contract")
  const NftTokenSale = await hre.ethers.getContractFactory("NftTokenSale");
  const marketContract = await NftTokenSale.deploy(token.address, utils.address);
  await marketContract.deployed();
  console.log("NFT Market contract deployed to:", marketContract.address);

  console.log("Deploying ERC1155 SoundVerse NFT contract");
  const SoundVerseERC1155 = await hre.ethers.getContractFactory("SoundVerseERC1155");
  const nft1155 = await SoundVerseERC1155.deploy(marketContract.address);
  await nft1155.deployed();
  console.log("SoundVerseERC1155 deployed to:", nft1155.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
