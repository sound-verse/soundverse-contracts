const { expect } = require("chai");

describe('Token contract', function () {

    let SoundVerseToken;
    let soundVerseToken;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        SoundVerseToken = await ethers.getContractFactory("SoundVerseToken");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    
        soundVerseToken = await SoundVerseToken.deploy(6000000000);
    });

    it('should set the right owner', async function() {
        expect(await soundVerseToken.contractOwner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
        const ownerBalance = await soundVerseToken.balanceOf(owner.address);
        expect(await soundVerseToken.totalSupply()).to.equal(ownerBalance);
    });

    it('initializes the contract with the correct values', async function () {
        const ownerBalance = await soundVerseToken.balanceOf(owner.address)
        expect(await soundVerseToken.totalSupply()).to.equal(ownerBalance)

    });

    it('transfers token ownership', async function () {
        await expect(soundVerseToken.connect(addr1).transfer(addr1.address, 9999999999999))
        .to.be.revertedWith("Not enough balance");
        
        await soundVerseToken.connect(owner).transfer(addr1.address, 1000000000);
        const addr1Balance = await soundVerseToken.balanceOf(addr1.address);
        expect(addr1Balance).to.equal(1000000000);

    });

    it('transfers token ownership - legacy', function () {
        return LiniftyToken.deployed().then(function (instance) {
            tokenInstance = instance;
            return tokenInstance.transfer.call(accounts[1], 9999999999999);
        }).then(assert.fail).catch(function (error) {
            assert(error.message.indexOf('revert') >= 0, 'error message must contain revert');
            return tokenInstance.transfer.call(accounts[1], 1000000000, { from: accounts[0] });
        }).then(function (success) {
            assert.equal(success, true, 'it returns true');
            return tokenInstance.transfer(accounts[1], 1000000000, { from: accounts[0] });
        }).then(function (receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Transfer', 'should be the "Transfer" event');
            assert.equal(receipt.logs[0].args.from, accounts[0], 'logs the account the tokens are transferred from');
            assert.equal(receipt.logs[0].args.to, accounts[1], 'logs the account the tokens are transferred to');
            assert.equal(receipt.logs[0].args.value, 1000000000, 'logs the transfer amount');
            return tokenInstance.balanceOf(accounts[1]);
        }).then(function (balance) {
            assert.equal(balance.toNumber(), 1000000000, 'adds the amount to the receiving account');
            return tokenInstance.balanceOf(accounts[0]);
        }).then(function (balance) {
            assert.equal(balance.toNumber(), 5000000000, 'deducts amount from the sending account')
        });
    });

    it('approves tokens for delegated transfers - legacay', function () {
        return LiniftyToken.deployed().then(function (instance) {
            tokenInstance = instance;
            return tokenInstance.approve.call(accounts[1], 100);
        }).then(function (success) {
            assert.equal(success, true, 'it returns true');
            return tokenInstance.approve(accounts[1], 100, { from: accounts[0] });
        }).then(function (receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
            assert.equal(receipt.logs[0].args.owner, accounts[0], 'logs the account the tokens are authorized by');
            assert.equal(receipt.logs[0].args.spender, accounts[1], 'logs the account the tokens are authorized to');
            assert.equal(receipt.logs[0].args.value, 100, 'logs the transfer amount');
            return tokenInstance.allowance(accounts[0], accounts[1]);
        }).then(function (allowance) {
            assert.equal(allowance.toNumber(), 100, 'stores the allowance for delegated transfer');
        });
    });


    it('handles delegated token transfers - legacy', function () {
        return LiniftyToken.deployed().then(function (instance) {
            tokenInstance = instance;
            fromAccount = accounts[2];
            toAccount = accounts[3];
            spendingAccount = accounts[4];
            return tokenInstance.transfer(fromAccount, 100, { from: accounts[0] });
        }).then(function (receipt) {
            return tokenInstance.approve(spendingAccount, 10, { from: fromAccount });
        }).then(function (receipt) {
            return tokenInstance.transferFrom(fromAccount, toAccount, 9999, { from: spendingAccount });
        }).then(assert.fail).catch(function (error) {
            assert(error.message.indexOf('revert') >= 0, 'can not transfer value larger than balance');
            return tokenInstance.transferFrom(fromAccount, toAccount, 20, { from: spendingAccount });
        }).then(assert.fail).catch(function (error) {
            assert(error.message.indexOf('revert') >= 0, 'can not transfer more than approbved');
            return tokenInstance.transferFrom.call(fromAccount, toAccount, 10, { from: spendingAccount });
        }).then(function (success) {
            assert.equal(success, true);
            return tokenInstance.transferFrom(fromAccount, toAccount, 10, { from: spendingAccount });
        }).then(function (receipt) {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Transfer', 'should be the "Transfer" event');
            assert.equal(receipt.logs[0].args.from, fromAccount, 'logs the account the tokens are transferred from');
            assert.equal(receipt.logs[0].args.to, toAccount, 'logs the account the tokens are transferred to');
            assert.equal(receipt.logs[0].args.value, 10, 'logs the transfer amount');
            return tokenInstance.balanceOf(fromAccount);
        }).then(function (balance) {
            assert.equal(balance.toNumber(), 90, 'deducts amount from sending account');
            return tokenInstance.balanceOf(toAccount);
        }).then(function (balance) {
            assert.equal(balance.toNumber(), 10, 'adds the amount from the receiving account');
            return tokenInstance.allowance(fromAccount, spendingAccount);
        }).then(function (allowance) {
            assert.equal(allowance.toNumber(), 0, 'deducts the amount from the allowence');
        });
    });


});