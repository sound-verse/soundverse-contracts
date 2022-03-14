const hre = require("hardhat");
const ethers = hre.ethers;
const config = require('../utils.config.json');

async function main() {
  const commonUtilsAddress = config.commonUtils;
  const percentageUtilsLibAddress = config.percentageUtilsLib;

  const MarketContract = await ethers.getContractFactory("MarketContract", {
    libraries: {
      PercentageUtils: percentageUtilsLibAddress,
    },
  });

  const CommonUtils = await ethers.getContractFactory("CommonUtils");
  const utils = await CommonUtils.attach(commonUtilsAddress);

  console.log("Deploying License contract");
  const License = await ethers.getContractFactory("License");
  const license = await License.deploy(commonUtilsAddress);
  await license.deployed();
  console.log("License deployed to:", license.address);

  await utils.setContractAddressFor("License", license.address);

  console.log("Deploying Master contract");
  const Master = await ethers.getContractFactory("Master");
  const master = await Master.deploy(commonUtilsAddress);
  await master.deployed();
  console.log("Master deployed to:", master.address);

  console.log("Deploying Market contract")
  const marketContract = await MarketContract.deploy(commonUtilsAddress);
  await marketContract.deployed();
  console.log("NFT Market contract deployed to:", marketContract.address);

  await utils.setContractAddressFor("Master", master.address);
  await utils.setContractAddressFor("MarketContract", marketContract.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
