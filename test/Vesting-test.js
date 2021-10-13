/* eslint-disable prettier/prettier */
const { expect } = require("chai");
const {time,BN, constants, expectEvent, expectRevert} = require("@openzeppelin/test-helpers");


describe("Vest.contract", function () {

    let SoundVerseTokenFactory;
    let soundVerseToken;
    let PercentageCalculatorFactory;
    let percentageCalculator;
    let VestingFactory;
    let vesting;
    let owner;
    let owner2;
    let addr1;
    let addr2;
    let addrs;
    
    
  beforeEach(async function () {
    
        SoundVerseTokenFactory = await ethers.getContractFactory("SoundVerseToken");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    
        soundVerseToken = await SoundVerseTokenFactory.deploy(1000000000);
    PercentageCalculatorFactory = await ethers.getContractFactory(
      "PercentageCalculator")
        percentageCalculator = await  PercentageCalculatorFactory.deploy();
        VestingFactory = await ethers.getContractFactory("Vesting",{
              libraries: {
                PercentageCalculator: percentageCalculator.address,
                  }
              });

        [owner2, addr1, addr2, ... addrs] = await ethers.getSigners();
        
    vesting = await VestingFactory.deploy(
      soundVerseToken.address,
      60,
      1000000)
    });

    

    it('should initialize correctly',async function(){
    
        expect(await vesting.paused()).to.equal(false);
        expect(await soundVerseToken.contractOwner()).to.equal(owner.address);
        expect(await vesting.cumulativeAmountToVest()).to.equal(1000000);
        
    });

    it('set StartDate should set the variable properly',async function(){
      const now = Date.now()
      vesting.setStartDate(now);
      expect(await vesting.startDate()).to.equal(now);
      

  });

});