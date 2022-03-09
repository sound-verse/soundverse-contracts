const { expect } = require("chai");

describe('NFT contract', function () {

    let Master;
    let CommonUtils;
    let tokenURIOne = "test-tokenuri.com/test1";
    let tokenURITwo = "test-tokenuri.com/test2";

    beforeEach(async function () {

        CommonUtils = await ethers.getContractFactory('CommonUtils');
        commonUtils = await CommonUtils.deploy()

        License = await ethers.getContractFactory('License');
        [owner, addr1, operator] = await ethers.getSigners();
        license = await License.deploy();

        await commonUtils.setContractAddressFor('License', license.address);
        
        Master = await ethers.getContractFactory('Master');
        [owner, addr1, operator] = await ethers.getSigners();
        master = await Master.deploy(commonUtils.address);

    });

    it('creates 1 Master Nft and its licenses', async function () {

        console.log("addr1.address",addr1.address);
        console.log("owner.address",owner.address);

        await expect(master.createMasterItem(addr1.address, owner.address, tokenURIOne, 2))
            .to.emit(master, 'MasterMintEvent')
            .withArgs(0);

        await expect(master.createMasterItem(addr1.address, owner.address, tokenURITwo, 3))
            .to.emit(master, 'MasterMintEvent')
            .withArgs(1);

    });

    it('should revert transaction if no tokenUri present', async function () {

        await expect(master.createMasterItem(addr1.address, owner.address, "", 2))
            .to.be.revertedWith("TokenUri can not be null");

    });

    it('should revert transaction if no number of licenses is less than 2', async function () {

        await expect(master.createMasterItem(addr1.address, owner.address, tokenURIOne, 1))
            .to.be.revertedWith("Supply must be greater than 2");

    });

    it('should call erc1155 contract', async function () {
        const masterId = await commonUtils.toBytes(1);

        // TransferSingle(operator, from, to, id, amount);
        await expect(license.connect(addr1).mintLicenses(owner.address, addr1.address, tokenURIOne, 2, masterId))
            .to.emit(license, 'TransferSingle')
            .withArgs(addr1.address, owner.address, addr1.address, 0, 1);

    });


});