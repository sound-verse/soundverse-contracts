const hre = require("hardhat");
const fs = require('fs');
const ethers = hre.ethers;

async function main() {

  console.log('PercentageUtils Library deployment')
  let percentageUtilsfactory = await ethers.getContractFactory("PercentageUtils");
  let percentageUtilsLib = await percentageUtilsfactory.deploy();
  await percentageUtilsLib.deployed()
  console.log('PercentageUtils Library deployment successful to address', percentageUtilsLib.address)

  console.log('CommonUtils Library deployment')
  let commonUtilsfactory = await ethers.getContractFactory("CommonUtils");
  let commonUtilsLib = await commonUtilsfactory.deploy();
  await commonUtilsLib.deployed()
  console.log('CommonUtils Library deployment successful to address', commonUtilsLib.address)

  console.log("Deploying ERC20 SoundVerse Token contract")
  const SoundVerseToken = await hre.ethers.getContractFactory("SoundVerseToken");
  const token = await SoundVerseToken.deploy();
  await token.deployed();
  console.log("SoundVerseToken deployed to:", token.address);

  console.log('Deploying SoundVerse vesting contract');
  const Vesting = await hre.ethers.getContractFactory('Vesting', {
    libraries: {
      PercentageUtils: percentageUtilsLib.address,
    },
  });
  const vest = await Vesting.deploy(token.address, [
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
  const MarketContract = await hre.ethers.getContractFactory("MarketContract", {
    libraries: {
      PercentageUtils: percentageUtilsLib.address,
    },
  });
  const marketContract = await MarketContract.deploy(token.address);
  await marketContract.deployed();
  console.log("NFT Market contract deployed to:", marketContract.address);

  console.log("Deploying ERC721 SoundVerse NFT contract");
  const SoundVerseERC721 = await hre.ethers.getContractFactory("SoundVerseERC721", {
    libraries: {
      CommonUtils: commonUtilsLib.address,
    },
  });
  const nft721 = await SoundVerseERC721.deploy(marketContract.address);
  await nft721.deployed();
  console.log("SoundVerseERC721 deployed to:", nft721.address);

  console.log("Deploying ERC1155 SoundVerse NFT contract");
  const SoundVerseERC1155 = await hre.ethers.getContractFactory("SoundVerseERC1155");
  const nft1155 = await SoundVerseERC1155.deploy(marketContract.address);
  await nft1155.deployed();
  console.log("SoundVerseERC1155 deployed to:", nft1155.address);

  console.log("Deploying CommonUtilsModifier");
  const CommonUtilsModifier = await hre.ethers.getContractFactory("CommonUtilsModifier", {
    libraries: {
      CommonUtils: commonUtilsLib.address,
    },
  });
  const commonUtilsModifier = await CommonUtilsModifier.deploy(nft721.address, nft1155.address, marketContract.address);
  await commonUtilsModifier.deployed();
  console.log("commonUtilsModifier deployed to:", nft721.address, nft1155.address, marketContract.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
