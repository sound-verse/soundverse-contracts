const hre = require("hardhat");
const ethers = hre.ethers;
const config = require("../utils.config.json");

async function main() {
  const commonUtilsAddress = config.commonUtils;

  const MarketContract = await ethers.getContractFactory("MarketContract");

  const CommonUtils = await ethers.getContractFactory("CommonUtils");
  const utils = await CommonUtils.attach(commonUtilsAddress);

  console.log("Deploying License contract");
  const License = await ethers.getContractFactory("License");
  const license = await License.deploy(commonUtilsAddress);
  await license.deployed();
  await utils.setContractAddressFor("License", license.address);
  console.log("License deployed to:", license.address);

  console.log("Deploying Master contract");
  const Master = await ethers.getContractFactory("Master");
  const master = await Master.deploy(commonUtilsAddress);
  await master.deployed();
  await utils.setContractAddressFor("Master", master.address);
  console.log("Master deployed to:", master.address);

  console.log("Deploying Market contract");
  const marketContract = await MarketContract.deploy(commonUtilsAddress);
  await marketContract.deployed();
  await utils.setContractAddressFor("MarketContract", marketContract.address);
  console.log("NFT Market contract deployed to:", marketContract.address);

  // const deploymentDataMarket = marketContract.interface.encodeDeploy([commonUtilsAddress]);
  // const estimatedGasMarket = await ethers.provider.estimateGas({ data: deploymentDataMarket });
  // console.log("Estimated gas for Market Contract", estimatedGasMarket.toNumber());

  // const deploymentDataMaster = master.interface.encodeDeploy([commonUtilsAddress]);
  // const estimatedGasMaster = await ethers.provider.estimateGas({ data: deploymentDataMaster });
  // console.log("Estimated gas for Master Contract", estimatedGasMaster.toNumber());

  // const deploymentDataLicense = license.interface.encodeDeploy([commonUtilsAddress]);
  // const estimatedGasLicense = await ethers.provider.estimateGas({ data: deploymentDataLicense });
  // console.log("Estimated gas for License Contract", estimatedGasLicense.toNumber());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
