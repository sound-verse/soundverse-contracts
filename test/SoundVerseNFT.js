const { expect } = require("chai");

describe('NFT contract', function () {

    let SoundVerseNFT;
    let soundVerseNFT;
    let tokenURIOne = "test-tokenuri.com/test1";
    let tokenURITwo = "test-tokenuri.com/test2"
    let tokenURIThree = "test-tokenuri.com/test3"
    let owner;
    let addr1;

    beforeEach(async function () {
        SoundVerseNFT = await ethers.getContractFactory("SoundVerseNFT");
        [owner, addr1] = await ethers.getSigners();

        soundVerseNFT = await SoundVerseNFT.deploy();
    });

    it('creates 2 unpublished items and returns the tokenId', async function () {

        await expect(soundVerseNFT.createUnpublishedItem([1], tokenURIOne, { value: ethers.utils.parseEther("0.1") }))
            .to.emit(soundVerseNFT, 'NewMintEvent')
            .withArgs(1);

        await expect(soundVerseNFT.createUnpublishedItem([2], tokenURITwo, { value: ethers.utils.parseEther("0.1") }))
            .to.emit(soundVerseNFT, 'NewMintEvent')
            .withArgs(2);

    });

    it('should revert transaction if not sufficient value transferred', async function (){

        await expect(soundVerseNFT.createUnpublishedItem([3], tokenURIThree, { value: ethers.utils.parseEther("0.01") }))
            .to.be.revertedWith("Value below price");

    });


});