const hre = require("hardhat");
const fs = require('fs');
const ethers = hre.ethers;

async function main() {

    console.log('CommonUtils deployment')
    const CommonUtils = await ethers.getContractFactory("CommonUtils");
    let commonUtils = await CommonUtils.deploy();
    await commonUtils.deployed()
    console.log('CommonUtils deployment successful to address', commonUtils.address);

    fs.appendFileSync('.env', 'COMMONUTILS=' + commonUtils.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });