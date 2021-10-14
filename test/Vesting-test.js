/* eslint-disable prettier/prettier */
const { expect } = require('chai')
const { network } = require('hardhat')

// can't use openzeppelin due to hardhat runtime env

// const {
//   time,
//   BN,
//   expectEvent,
//   expectRevert,
// } = require('@openzeppelin/test-helpers')

describe('Vest.contract', function () {
  let SoundVerseTokenFactory
  let soundVerseToken
  let PercentageCalculatorFactory
  let percentageCalculator
  let VestingFactory
  let vesting
  let owner
  let owner2
  let addr1
  let addr2
  let addr3
  let addrs
  let startTime

  beforeEach(async function () {
    SoundVerseTokenFactory = await ethers.getContractFactory('SoundVerseToken')
    ;[owner, addr1, addr2, ...addrs] = await ethers.getSigners()

    soundVerseToken = await SoundVerseTokenFactory.deploy(1000000000)
    PercentageCalculatorFactory = await ethers.getContractFactory(
      'PercentageCalculator',
    )
    percentageCalculator = await PercentageCalculatorFactory.deploy()
    VestingFactory = await ethers.getContractFactory('Vesting', {
      libraries: {
        PercentageCalculator: percentageCalculator.address,
      },
    })
    ;[owner2, addr1, addr2, addr3, ...addrs] = await ethers.getSigners()

    vesting = await VestingFactory.deploy(soundVerseToken.address, 60, 1000000)
  })

  it('should initialize correctly', async function () {
    expect(await vesting.paused()).to.equal(false)
    expect(await soundVerseToken.contractOwner()).to.equal(owner.address)
    expect(await vesting.cumulativeAmountToVest()).to.equal(1000000)
  })

  // Tests @function addRecipient
  it('Adds an Investor & fails on more than 100% allo', async function () {
    const now = Date.now()
    await expect(await vesting.addRecipient(addr1.address, 100000, now, now))
      .to.emit(vesting, 'LogRecipientAdded')
      .withArgs(addr1.address, 100000)
    await expect(
      vesting.addRecipient(addr2.address, 100000, now, now),
    ).to.be.revertedWith('Total percentages exceeds 100%')
  })

  // Tests @function addMultipleRecipients
  it('Adds multiple Investors & fails on more than 100% allo', async function () {
    const now = Date.now()
    const address1 = addr1.address
    const address2 = addr2.address
    await vesting.addMultipleRecipients(
      [address1, address2],
      [10000, 80000],
      [now, now],
      [now, now],
    )
    await expect(await vesting.getRecipient(address1)).to.equal(10000)
    await expect(await vesting.getRecipient(address2)).to.equal(80000)
    await expect(
      vesting.addMultipleRecipients([addr3.address], [20000], [now], [now]),
    ).to.be.revertedWith('Total percentages exceeds 100%')
  })

  // this is the problem test
  describe('When enough time has passed to claim', () => {
    beforeEach(async () => {
      await network.provider.send('evm_setAutomine', [true])
    })

    it('Claims for recipients and checks edge cases', async function () {
      const now = Date.now()
      const address1 = addr1.address
      const address2 = addr2.address
      await vesting.addMultipleRecipients(
        [address1, address2],
        [10000, 80000],
        [now, now],
        [now, now],
      )
      // not sure how to get hardhat to wait for the 
      // transaction to complete before moving forward

      // await new Promise((r) => setTimeout(r, 2000))
      await expect(await vesting.connect(addr3).claim())
        .to.emit(vesting, 'LogTokensClaimed')
        .withArgs(addr3.address, 0)
    })
  })
})
