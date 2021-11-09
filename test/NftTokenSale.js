const { expect } = require("chai");

describe("NftTokenSale.contract", function () {

    let soundVerseERC1155;
    let nftTokenSale;
    let owner;
    let addr1;
    const firstTokenId = 845;
    let tokenPrice = 1000000000000; // in wei, about 0,000001 ether
    let tokensAmount = 10;
    let uri = 'https://token.com';
    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

    beforeEach(async function () {
        SoundVerseERC1155Factory = await ethers.getContractFactory('SoundVerseERC1155')
        soundVerseERC1155 = await SoundVerseERC1155Factory.deploy(uri)

        NftTokenSaleFactory = await ethers.getContractFactory("NftTokenSale");
        [owner, addr1] = await ethers.getSigners();
        nftTokenSale = await NftTokenSaleFactory.deploy(soundVerseERC1155.address);

        expect(await soundVerseERC1155.mint(owner.address, firstTokenId, tokensAmount, '0x', { from: owner.address }));
    })

    it('should initialize correctly', async function () {
        expect(await soundVerseERC1155.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(owner.address);
        expect(await nftTokenSale.nftContract()).to.equal(soundVerseERC1155.address)
    })

    it('should throw error if not buying for the correct amount', async function () {
        let price = (tokenPrice * 5) + 1
        await expect(nftTokenSale.purchaseTokens(owner.address, firstTokenId, price, tokensAmount, { value: price }))
            .to.be.revertedWith("Not the correct price amount")
    })

    it('should throw error if buying more than total amount', async function () {
        let moreThanTotalAmount = tokensAmount + 2
        let price = tokenPrice * moreThanTotalAmount

        await expect(nftTokenSale.purchaseTokens(owner.address, firstTokenId, tokenPrice, moreThanTotalAmount, { value: price }))
            .to.be.revertedWith("Can not buy more than available")
    })

    it('should facilitate purchasing tokens', async function () {
        let purchaseAmount = tokensAmount - 5
        let purchasePrice = tokenPrice * purchaseAmount

        await expect(nftTokenSale.connect(addr1).purchaseTokens(owner.address, firstTokenId, tokenPrice, purchaseAmount, { value: purchasePrice }))
            .to.emit(nftTokenSale, 'SoldNFT')
            .withArgs(owner.address, addr1.address, firstTokenId, purchaseAmount, purchasePrice)
    })

    it('should return balance of address', async function () {
        expect(await nftTokenSale.getThisAddressTokenBalance(owner.address, firstTokenId)).to.equal(10)
    })

    it('Should throw error if price being set is equal to zero', async function () {
        await expect(nftTokenSale.setCurrentPrice(0)).
            to.be.revertedWith("Current price must be greater than zero")
    })

    it('Should throw error trying to withdraw zero', async function () {
        await expect(nftTokenSale.withdrawTo({ value: 0 }))
            .to.be.revertedWith("Not able to withdraw zero")
    })

    it('Should be able to withdraw to owner', async function () {

        await expect(nftTokenSale.withdrawTo({ value: 100 }))
            .to.emit(nftTokenSale, 'Withdrawal')
            .withArgs(owner.address, 100)
    })

});