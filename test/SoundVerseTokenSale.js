const { expect } = require("chai");

describe("TokenSale.contract", function () {

    let soundVerseToken;
    let soundVerseTokenSale;
    let owner;
    let addr1;
    let tokenPrice = 1000000000000; // in wei, about 0,000001 ether
    let tokensAvailable = 10;

    beforeEach(async function () {
        SoundVerseTokenFactory = await ethers.getContractFactory('SoundVerseToken')

        soundVerseToken = await SoundVerseTokenFactory.deploy(tokensAvailable)

        SoundVerseTokenSaleFactory = await ethers.getContractFactory("SoundVerseTokenSale");
        [owner, addr1] = await ethers.getSigners();

        soundVerseTokenSale = await SoundVerseTokenSaleFactory.deploy(soundVerseToken.address, tokenPrice);

        await soundVerseToken.transfer(soundVerseTokenSale.address, tokensAvailable, { from: owner.address })
    })

    it('should initialize correctly', async function () {
        expect(await soundVerseToken.contractOwner()).to.equal(owner.address)
        expect(await soundVerseTokenSale.tokenContract()).to.equal(soundVerseToken.address)
        expect(await soundVerseTokenSale.tokenPrice()).to.equal(tokenPrice)
    })

    it('should throw error if not buying for the correct amount', async function () {
        await expect(soundVerseTokenSale.buyTokens(5, { value: 5 * tokenPrice - 1 }))
            .to.be.revertedWith("Not the correct price amount")
    })

    it('should throw error if buying more than total amount', async function () {
        await expect(soundVerseTokenSale.buyTokens(tokensAvailable + 1, { value: (tokensAvailable + 1) * tokenPrice }))
            .to.be.revertedWith("Can not buy more than available")
    })

    it('should facilitate buying tokens', async function () {

        await expect(soundVerseTokenSale.buyTokens(5, { value: 5 * tokenPrice }))
            .to.emit(soundVerseTokenSale, 'Sell')
            .withArgs(owner.address, 5)

        expect(await soundVerseTokenSale.tokensSold()).to.equal(5)

    })

    it('should increment tokens sold after buying', async function () {

        expect(await soundVerseTokenSale.tokensSold()).to.equal(0)

        await soundVerseTokenSale.buyTokens(2, { value: 2 * tokenPrice })

        expect(await soundVerseTokenSale.tokensSold()).to.equal(2)

    })

    it('should end token sale', async function () {

        await expect(soundVerseTokenSale.connect(addr1).buyTokens(2, { value: 2 * tokenPrice }))
            .to.emit(soundVerseTokenSale, 'Sell')
            .withArgs(addr1.address, 2)

        await soundVerseTokenSale.endSale()

        expect(await soundVerseToken.balanceOf(owner.address)).to.equal(8)

    })

    it('should return balance of address', async function () {

        expect(await soundVerseTokenSale.getThisAddressTokenBalance()).to.equal(10)

    })

});