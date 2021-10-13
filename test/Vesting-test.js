const { expect } = require("chai");


describe("Vest.contract", function () {

    let SoundVerseToken;
    let soundVerseToken;
    let owner;
    let addr1;
    let addr2;
    let addrs;

  beforeEach(async function () {
        SoundVerseTokenFactory = await ethers.getContractFactory("SoundVerseToken");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    
        soundVerseToken = await SoundVerseTokenFactory.deploy(1000000000);
    PercentageCalculatorFactory = await ethers.getContractFactory(
      "PercentageCalculator")
        percentageCalculator = await  PercentageCalculatorFactory.deploy(1000000000);
        VestingFactory = await ethers.getContractFactory("Vesting",{
              libraries: {
                PercentageCalculator: "",
                  }
              });

        [owner, addr1, addr2, ... adrs] = await ethers.getSigners;
        
        vesting = await Vesting.deploy(1000000000);
    });

    it('should initialize correctly',async function(){
        expect(await vesting.contractOwner()).to.equal(owner.address);
        expect(await soundVerseToken.contractOwner().to.equal(owner.address));
        

    });
});