const { expect } = require("chai");

describe("NftTokenSale.contract", function () {

    let soundVerseERC1155;
    let nftTokenSale;
    let tokenContract;
    let owner;
    let addr1;
    let addr2;
    let addr3;
    const firstTokenId = 845;
    let tokenPrice = 1000000000000; // in wei, about 0,000001 ether
    let tokensAmount = 10;
    let uri = 'https://token.com';
    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';

    const tokenAmountTier1 = ethers.BigNumber.from('1100000');
    const tokenAmountTier2 = ethers.BigNumber.from('650000');
    const tokenAmountTier3 = ethers.BigNumber.from('350000');

    beforeEach(async function () {
        SoundVerseERC1155Factory = await ethers.getContractFactory('SoundVerseERC1155')
        soundVerseERC1155 = await SoundVerseERC1155Factory.deploy(uri)

        SoundVerseTokenFactory = await ethers.getContractFactory('SoundVerseToken')
        tokenContract = await SoundVerseTokenFactory.deploy();

        NftTokenSaleFactory = await ethers.getContractFactory("NftTokenSale");
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        nftTokenSale = await NftTokenSaleFactory.deploy(soundVerseERC1155.address, tokenContract.address);

        expect(await soundVerseERC1155.mint(owner.address, firstTokenId, tokensAmount, '0x', { from: owner.address }));
        expect(await tokenContract.transfer(addr1.address, tokenAmountTier1));
        expect(await tokenContract.transfer(addr2.address, tokenAmountTier2));
        expect(await tokenContract.transfer(addr3.address, tokenAmountTier3));
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
        let purchasePrice = 5000000000000 + 150000000000

        await expect(nftTokenSale.connect(addr1).purchaseTokens(owner.address, firstTokenId, tokenPrice, purchaseAmount, { value: purchasePrice }))
            .to.emit(nftTokenSale, 'SoldNFT')
            .withArgs(owner.address, addr1.address, firstTokenId, purchaseAmount, purchasePrice)
    })

    it('should return balance of address', async function () {
        expect(await nftTokenSale.getThisAddressTokenBalance(owner.address, firstTokenId)).to.equal(10)
    })

    it('Should get correct service fees tier from user', async function () {
        // Tier 1 service Fees *10
        expect(await nftTokenSale.currentFeesTierFromUser(addr1.address)).to.equal(3)
        // Tier 2 service Fees *10
        expect(await nftTokenSale.currentFeesTierFromUser(addr2.address)).to.equal(4)
        // Tier 3 service Fees *10
        expect(await nftTokenSale.currentFeesTierFromUser(addr3.address)).to.equal(5)

    })

    it('Should extract fees and transfer', async function () {
        const tierOneUserFees = await nftTokenSale.currentFeesTierFromUser(addr1.address)
        const parsedDecimalElevated = ethers.utils.parseUnits(tierOneUserFees.toString(), 17)
        const formattedDecimal = ethers.utils.formatEther(parsedDecimalElevated)

        await expect(nftTokenSale.extractFeesAndTransfer(100, parsedDecimalElevated, { value: parsedDecimalElevated }))
            .to.emit(nftTokenSale, 'Withdrawal')
            .withArgs(owner.address, formattedDecimal)
    })

    // it('Should be able to withdraw to owner', async function () {

    //     await expect(nftTokenSale.withdrawTo({ value: 100 }))
    //         .to.emit(nftTokenSale, 'Withdrawal')
    //         .withArgs(owner.address, 100)
    // })

});