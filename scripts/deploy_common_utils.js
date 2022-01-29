const hre = require("hardhat");
const fs = require('fs');
const ethers = hre.ethers;
const config = require("../utils.config.json");
var path = require('path');

async function main() {

    const configFile = path.dirname(__dirname)

    console.log('CommonUtils deployment')
    const CommonUtils = await ethers.getContractFactory("CommonUtils");
    let commonUtils = await CommonUtils.deploy();
    await commonUtils.deployed()
    console.log('CommonUtils deployment successful to address', commonUtils.address);

    config.address = commonUtils.address;
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