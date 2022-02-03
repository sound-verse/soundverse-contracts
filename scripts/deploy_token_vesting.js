const hre = require("hardhat");
const fs = require('fs');
const ethers = hre.ethers;
const config = require("../utils.config.json");
var path = require('path');

async function main() {

    const configFile = path.dirname(__dirname)

    const percentageUtilsLibAddress = config.percentageUtilsLib;

    console.log("Deploying ERC20 SoundVerse Token contract")
    const SoundVerseToken = await ethers.getContractFactory("SoundVerseToken");
    const token = await SoundVerseToken.deploy();
    await token.deployed();
    console.log("SoundVerseToken deployed to:", token.address);

    console.log('Deploying SoundVerse vesting contract');
    const Vesting = await ethers.getContractFactory('Vesting', {
        libraries: {
            PercentageUtils: percentageUtilsLibAddress,
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

    config.erc20 = token.address;
    config.vesting = vest.address;
    try {
        fs.writeFileSync(`${configFile}/utils.config.json`, JSON.stringify(config));
    } catch(error){
        console.error(error);
    }

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });