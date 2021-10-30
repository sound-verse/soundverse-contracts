const hre = require("hardhat");
const fs = require('fs');

async function main() {
  const date = new Date().getTime + 20 * 60 * 1000

  console.log("Deploying ERC20 SoundVerse Token contract")

  const SoundVerseToken = await hre.ethers.getContractFactory("SoundVerseToken");
  const SoundVerseTokenSale = await hre.ethers.getContractFactory("SoundVerseTokenSale");
  const Vesting = await hre.ethers.getContractFactory('Vesting')

  const token = await SoundVerseToken.deploy(900000000);
  await token.deployed();
  
  console.log("SoundVerseToken deployed to:", token.address);
  console.log("Deploying SoundVerseTokenSale");

  // 0.02 usd = 0,0000048 eth = 4800000000000 wei
  const tokenSale = await SoundVerseTokenSale.deploy(token.address, 4800000000000);
  await tokenSale.deployed;

  console.log("SoundVerseTokenSale deployed");

  const vest = await Vesting.deploy(token.address, date, [
    1000000,
    1000000,
    1000000,
    1000000,
    1000000,
    1000000,
  ])
  await vest.deployed

  console.log('SoundVerseToken deployed to:', token.address)
  console.log('SoundVerseToken deployed to:', vest.ddress)

  console.log("Deploying ERC721 SoundVerse NFT contract")

  const SoundVerseERC721 = await hre.ethers.getContractFactory("SoundVerseERC721");
  const nft721 = await SoundVerseERC721.deploy();
  await nft721.deployed();
  console.log("SoundVerseERC721 deployed to:", nft721.address);

  console.log("Deploying ERC1155 SoundVerse NFT contract")

  const SoundVerseERC1155 = await hre.ethers.getContractFactory("SoundVerseERC1155");
  const nft1155 = await SoundVerseERC1155.deploy();
  await nft1155.deployed();
  console.log("SoundVerseERC721 deployed to:", nft1155.address);
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
