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
        nftTokenSale = await NftTokenSaleFactory.deploy(soundVerseERC1155.address, tokenPrice);

        expect(await soundVerseERC1155.mint(owner.address, firstTokenId, tokensAmount, '0x', { from: owner.address }));
    })

    it('should initialize correctly', async function () {
        expect(await soundVerseERC1155.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(owner.address);
        expect(await nftTokenSale.nftContract()).to.equal(soundVerseERC1155.address)
        expect(await nftTokenSale.tokenPrice()).to.equal(tokenPrice)
    })

    it('should throw error if not buying for the correct amount', async function () {
        await expect(nftTokenSale.purchaseTokens(owner.address, firstTokenId, tokensAmount, { value: 5 * tokenPrice - 1 }))
            .to.be.revertedWith("Not the correct price amount")
    })

    it('should throw error if buying more than total amount', async function () {
        await expect(nftTokenSale.purchaseTokens(owner.address, firstTokenId, tokensAmount + 1, { value: (tokensAmount + 1) * tokenPrice }))
            .to.be.revertedWith("Can not buy more than available")
    })

    it('should facilitate purchasing tokens', async function () {
        await expect(nftTokenSale.connect(addr1).purchaseTokens(owner.address, firstTokenId, (tokensAmount - 5), { value: (tokensAmount - 5) * tokenPrice }))
            .to.emit(nftTokenSale, 'SoldNFT')
            .withArgs(owner.address, addr1.address, firstTokenId, tokensAmount - 5)
    })

    it('should return balance of address', async function () {
        expect(await nftTokenSale.getThisAddressTokenBalance(owner.address, firstTokenId)).to.equal(10)
    })

    it('Throw error if trying to change price and not owner', async function () {
        await expect(nftTokenSale.connect(addr1).setCurrentPrice((tokenPrice * 2))).
            to.be.revertedWith("Ownable: caller is not the owner")
    })

    it('Should throw error if price being set is equal to zero', async function () {
        await expect(nftTokenSale.setCurrentPrice(0)).
            to.be.revertedWith("Current price must be greater than zero")
    })

    it('Should throw error if payee is not the owner', async function () {
        await expect(nftTokenSale.connect(addr1).withdrawTo(addr1.address, tokenPrice)).
            to.be.revertedWith("Ownable: caller is not the owner")
    })

    it('Should throw error trying to withdraw zero', async function () {
        await expect(nftTokenSale.withdrawTo(addr1.address, 0))
            .to.be.revertedWith("Not able to withdraw zero")
    })

    // FIX ME!!!
    it('Should be able to withdraw to owner', async function () {
        await nftTokenSale.transfer(1000);

        await expect(nftTokenSale.withdrawTo(owner.address, 100, {from: owner.address}))
            .to.emit(nftTokenSale, 'Withdrawal')
            .withArgs(owner.address, 100)
    })

});