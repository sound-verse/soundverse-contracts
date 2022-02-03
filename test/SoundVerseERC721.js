const { constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");

describe('NFT contract', function () {

    let SoundVerseERC721;
    let CommonUtils;
    let tokenURIOne = "test-tokenuri.com/test1";
    let tokenURITwo = "test-tokenuri.com/test2";

    beforeEach(async function () {

        CommonUtils = await ethers.getContractFactory('CommonUtils');
        commonUtils = await CommonUtils.deploy()

        SoundVerseERC1155 = await ethers.getContractFactory('SoundVerseERC1155');
        [owner, addr1] = await ethers.getSigners();
        soundVerseERC1155 = await SoundVerseERC1155.deploy();

        await commonUtils.setContractAddressFor('SoundVerseERC1155', soundVerseERC1155.address);

        SoundVerseERC721 = await ethers.getContractFactory('SoundVerseERC721');
        [owner, addr1] = await ethers.getSigners();
        soundVerseERC721 = await SoundVerseERC721.deploy(commonUtils.address);

    });

    it('creates 1 Master Nft and its licenses', async function () {

        await expect(soundVerseERC721.createMasterItem(tokenURIOne, 2))
            .to.emit(soundVerseERC721, 'MasterMintEvent')
            .withArgs(0);

        await expect(soundVerseERC721.createMasterItem(tokenURITwo, 3))
            .to.emit(soundVerseERC721, 'MasterMintEvent')
            .withArgs(1);

    });

    it('should revert transaction if no tokenUri present', async function () {

        await expect(soundVerseERC721.createMasterItem("", 2))
            .to.be.revertedWith("TokenUri can not be null");

    });

    it('should revert transaction if no number of licenses is less than 2', async function () {

        await expect(soundVerseERC721.createMasterItem(tokenURIOne, 1))
            .to.be.revertedWith("Supply must be greater than 2");

    });


});