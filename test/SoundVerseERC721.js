const { expect } = require("chai");

describe('NFT contract', function () {

    let SoundVerseERC721;
    let soundVerseERC721;
    let tokenURIOne = "test-tokenuri.com/test1";
    let tokenURITwo = "test-tokenuri.com/test2"

    beforeEach(async function () {
        SoundVerseTokenFactory = await ethers.getContractFactory('SoundVerseToken')
        tokenContract = await SoundVerseTokenFactory.deploy();

        PercentageUtils = await ethers.getContractFactory("PercentageUtils");
        utils = await PercentageUtils.deploy();

        MarketContractFactory = await ethers.getContractFactory("MarketContract");
        [owner, addr1] = await ethers.getSigners();
        marketContract = await MarketContractFactory.deploy(tokenContract.address, utils.address);

        SoundVerseERC721 = await ethers.getContractFactory("SoundVerseERC721");
        [owner, addr1] = await ethers.getSigners();
        soundVerseERC721 = await SoundVerseERC721.deploy(marketContract.address);
    });

    it('creates 2 unpublished items and returns the tokenId', async function () {

        await soundVerseERC721.addAllowedURI(tokenURIOne)
        await soundVerseERC721.addAllowedURI(tokenURITwo)

        await expect(soundVerseERC721.createUnpublishedItem(tokenURIOne))
            .to.emit(soundVerseERC721, 'NewMintEvent')
            .withArgs(0);

        await expect(soundVerseERC721.createUnpublishedItem(tokenURITwo))
            .to.emit(soundVerseERC721, 'NewMintEvent')
            .withArgs(1);

    });

    it('should revert transaction if no tokenUri present', async function (){

        await soundVerseERC721.addAllowedURI(tokenURIOne)

        await expect(soundVerseERC721.createUnpublishedItem("badURI"))
            .to.be.revertedWith("TokenURI must be allowed");

    });


});