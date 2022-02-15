const { expect } = require("chai");

describe("MarketCOntract.contract", function () {

    let soundVerseERC1155;
    let marketContract;
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
    let nftContractAddress = '0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9';

    const tokenAmountTier1 = ethers.BigNumber.from('1100000');
    const tokenAmountTier2 = ethers.BigNumber.from('650000');
    const tokenAmountTier3 = ethers.BigNumber.from('350000');
    it('should facilitate purchasing tokens', async function () {

        SoundVerseTokenFactory = await ethers.getContractFactory('SoundVerseToken')
        tokenContract = await SoundVerseTokenFactory.deploy();

        const PercentageUtils = await ethers.getContractFactory("PercentageUtils");
        percentageUtils = await PercentageUtils.deploy();

        MarketContractFactory = await ethers.getContractFactory("MarketContract", {
            libraries: {
                PercentageUtils: percentageUtils.address,
            },
        });
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        marketContract = await MarketContractFactory.deploy(tokenContract.address);

        SoundVerseERC1155Factory = await ethers.getContractFactory('SoundVerseERC1155')
        soundVerseERC1155 = await SoundVerseERC1155Factory.deploy();

        expect(await soundVerseERC1155.mintLicenses(owner.address, uri, tokensAmount, '0x', { from: owner.address }));
        expect(await tokenContract.transfer(addr1.address, tokenAmountTier1));
        expect(await tokenContract.transfer(addr2.address, tokenAmountTier2));
        expect(await tokenContract.transfer(addr3.address, tokenAmountTier3));

        expect(await soundVerseERC1155.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(owner.address);

        //should throw error if not buying for the correct amount
        let price = (tokenPrice * 5) + 1
        await expect(marketContract.purchaseTokens(owner.address, firstTokenId, price, tokensAmount, nftContractAddress, { value: price }))
            .to.be.revertedWith("Not the correct price amount")

        //should throw error if buying more than total amount
        let moreThanTotalAmount = tokensAmount + 2
        price = tokenPrice * moreThanTotalAmount

        await expect(marketContract.purchaseTokens(owner.address, firstTokenId, tokenPrice, moreThanTotalAmount, nftContractAddress, { value: price }))
            .to.be.revertedWith("Can not buy more than available")


        let purchaseAmount = 5
        let netPurchasePrice = tokenPrice * purchaseAmount
        let purchasePrice = netPurchasePrice + 150000000000

        await expect(marketContract.connect(addr1).purchaseTokens(owner.address, firstTokenId, tokenPrice, purchaseAmount, nftContractAddress, { value: purchasePrice }))
            .to.emit(marketContract, 'SoldNFT')
            .withArgs(owner.address, addr1.address, firstTokenId, purchaseAmount, netPurchasePrice)

        //should return balance of address
        expect(await marketContract.getThisAddressTokenBalance(owner.address, firstTokenId, nftContractAddress)).to.equal(5)

        //Should get correct service fees tier from user
        // Tier 1 service Fees *1000
        expect(await marketContract.currentFeesTierFromUser(addr1.address)).to.equal(3000)
        // Tier 2 service Fees *1000
        expect(await marketContract.currentFeesTierFromUser(addr2.address)).to.equal(4000)
        // Tier 3 service Fees *1000
        expect(await marketContract.currentFeesTierFromUser(addr3.address)).to.equal(5000)

        //Should extract fees and transfer
        const tierOneUserFees = await marketContract.currentFeesTierFromUser(addr1.address)
        purchaseAmount = 5
        netPurchasePrice = tokenPrice * purchaseAmount

        await expect(marketContract.extractFeesAndTransfer(netPurchasePrice, tierOneUserFees))
            .to.emit(marketContract, 'Withdrawal')
            .withArgs(owner.address, 150000000000)

    })

});