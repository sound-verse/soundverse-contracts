const hre = require("hardhat");
const fs = require('fs');
const ethers = hre.ethers;
const config = require("../utils.config.json");
var path = require('path');

async function main() {

    const configFile = path.dirname(__dirname)

    console.log('PercentageUtils Library deployment')
    let percentageUtilsfactory = await ethers.getContractFactory("PercentageUtils");
    let percentageUtilsLib = await percentageUtilsfactory.deploy();
    await percentageUtilsLib.deployed()
    console.log('PercentageUtils Library deployment successful to address', percentageUtilsLib.address);

    config.percentageUtilsLib = percentageUtilsLib.address;
    try {
        fs.writeFileSync(`${configFile}/utils.config.json`, JSON.stringify(config));
    } catch (error) {
        console.error(error);
    }

} main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });