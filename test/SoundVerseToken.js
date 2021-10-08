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

    it('should transfer token ownership', async function () {
        await expect(soundVerseToken.connect(addr1).transfer(addr2.address, 9999999999999))
        .to.be.revertedWith("Not enough balance");
        
        await soundVerseToken.transfer(addr1.address, 1000000000);
        const addr1Balance = await soundVerseToken.balanceOf(addr1.address);
        expect(addr1Balance).to.equal(1000000000);

    });

    it("Should update balances after transfers", async function () {
        const initialOwnerBalance = await soundVerseToken.balanceOf(owner.address);
  
        await soundVerseToken.transfer(addr1.address, 100);
  
        await soundVerseToken.transfer(addr2.address, 50);
  
        const finalOwnerBalance = await soundVerseToken.balanceOf(owner.address);
        expect(finalOwnerBalance).to.equal(initialOwnerBalance - 150);
  
        const addr1Balance = await soundVerseToken.balanceOf(addr1.address);
        expect(addr1Balance).to.equal(100);
  
        const addr2Balance = await soundVerseToken.balanceOf(addr2.address);
        expect(addr2Balance).to.equal(50);
      });

});