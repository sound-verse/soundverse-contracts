const hre = require("hardhat");
const ethers = hre.ethers;
const config = require('../utils.config.json');

async function main() {
  const commonUtilsAddress = config.commonUtils;
  const percentageUtilsLibAddress = config.percentageUtilsLib;

  console.log("Deploying NFT Market contract")
  const MarketContract = await ethers.getContractFactory("MarketContract", {
    libraries: {
      PercentageUtils: percentageUtilsLibAddress,
    },
  });

  const CommonUtils = await ethers.getContractFactory("CommonUtils");
  const utils = await CommonUtils.attach(commonUtilsAddress);

  console.log("Deploying ERC1155 SoundVerse NFT contract");
  const SoundVerseERC1155 = await ethers.getContractFactory("SoundVerseERC1155");
  const nft1155 = await SoundVerseERC1155.deploy(commonUtilsAddress);
  await nft1155.deployed();
  console.log("SoundVerseERC1155 deployed to:", nft1155.address);

  await utils.setContractAddressFor("SoundVerseERC1155", nft1155.address);

  console.log("Deploying ERC721 SoundVerse NFT contract");
  const SoundVerseERC721 = await ethers.getContractFactory("SoundVerseERC721");
  const nft721 = await SoundVerseERC721.deploy(commonUtilsAddress);
  await nft721.deployed();
  console.log("SoundVerseERC721 deployed to:", nft721.address);

  const marketContract = await MarketContract.deploy(commonUtilsAddress);
  await marketContract.deployed();
  console.log("NFT Market contract deployed to:", marketContract.address);

  await utils.setContractAddressFor("SoundVerseERC721", nft721.address);
  await utils.setContractAddressFor("MarketContract", marketContract.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
