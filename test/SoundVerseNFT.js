const { expect } = require("chai");

describe('NFT contract', function () {

    let SoundVerseNFT;
    let soundVerseNFT;
    let tokenURIOne = "test-tokenuri.com/test1";
    let tokenURITwo = "test-tokenuri.com/test2"
    let owner;
    let addr1;

    beforeEach(async function () {
        SoundVerseNFT = await ethers.getContractFactory("SoundVerseNFT");
        [owner, addr1] = await ethers.getSigners();

        soundVerseNFT = await SoundVerseNFT.deploy();
    });

    it('creates 2 unpublished items and returns the tokenId', async function () {

        await soundVerseNFT.addAllowedURI(tokenURIOne)
        await soundVerseNFT.addAllowedURI(tokenURITwo)

        await expect(soundVerseNFT.createUnpublishedItem(tokenURIOne))
            .to.emit(soundVerseNFT, 'NewMintEvent')
            .withArgs(0);

        await expect(soundVerseNFT.createUnpublishedItem(tokenURITwo))
            .to.emit(soundVerseNFT, 'NewMintEvent')
            .withArgs(1);

    });

    it('should revert transaction if no tokenUri present', async function (){

        await soundVerseNFT.addAllowedURI(tokenURIOne)

        await expect(soundVerseNFT.createUnpublishedItem("badURI"))
            .to.be.revertedWith("TokenURI must be allowed");

    });


});