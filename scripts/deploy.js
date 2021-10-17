const hre = require("hardhat");
const fs = require('fs');

async function main() {

  console.log("Deploying ERC20 SoundVerse Token contract")

  const SoundVerseToken = await hre.ethers.getContractFactory("SoundVerseToken");
  const token = await SoundVerseToken.deploy(900000000);
  await token.deployed();
  console.log("SoundVerseToken deployed to:", token.address);

  console.log("Deploying ERC721 SoundVerse NFT contract")

  const SoundVerseNFT = await hre.ethers.getContractFactory("SoundVerseNFT");
  const nft = await SoundVerseNFT.deploy();
  await nft.deployed();
  console.log("SoundVerseNFT deployed to:", nft.address);
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });