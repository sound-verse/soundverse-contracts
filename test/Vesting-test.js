/* eslint-disable prettier/prettier */
const { expect } = require('chai')
const { ethers } = require('hardhat')
const { network } = require('hardhat')

describe('Vest.contract', function () {
  let SoundVerseTokenFactory
  let soundVerseToken
  let PercentageCalculatorFactory
  let VestingFactory
  let vesting
  let owner
  let owner2
  let addr1
  let addr2
  let addr3
  let addrs
  let timestampBefore
  let timestampAfter

  beforeEach(async function () {
    SoundVerseTokenFactory = await ethers.getContractFactory('SoundVerseToken')
    ;[owner, addr1, addr2, ...addrs] = await ethers.getSigners()

    soundVerseToken = await SoundVerseTokenFactory.deploy()

    const PercentageUtils = await ethers.getContractFactory("PercentageUtils");
    utils = await PercentageUtils.deploy();

    VestingFactory = await ethers.getContractFactory('Vesting')
    ;[owner2, addr1, addr2, addr3, ...addrs] = await ethers.getSigners()

    vesting = await VestingFactory.deploy(soundVerseToken.address, utils.address, [
      1000000,
      1000000,
      1000000,
      1000000,
      1000000,
      1000000,
    ])
  })

  it('should initialize correctly', async function () {
    expect(await vesting.paused()).to.equal(false)
    expect(await soundVerseToken.contractOwner()).to.equal(owner.address)
    expect(await vesting.cumulativeAmountToVest(1)).to.equal(1000000)
  })

  // Tests @function addRecipient
  it('Adds an Investor & fails on more than 100% allo', async function () {
    const now = Date.now()
    await expect(await vesting.addRecipient(addr1.address, 100000, now))
      .to.emit(vesting, 'LogRecipientAdded')
      .withArgs(addr1.address, 100000)
    await expect(
      vesting.addRecipient(addr2.address, 100000, now),
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
    )
    await expect(await vesting.getRecipient(address1)).to.equal(10000)
    await expect(await vesting.getRecipient(address2)).to.equal(80000)
    await expect(
      vesting.addMultipleRecipients([addr3.address], [20000], [now]),
    ).to.be.revertedWith('Total percentages exceeds 100%')
  })

  describe('When enough time has passed to claim', () => {
    beforeEach(async () => {
      const sevenDays = 90 * 24 * 60 * 60

      const blockNumBefore = await ethers.provider.getBlockNumber()
      const blockBefore = await ethers.provider.getBlock(blockNumBefore)
      timestampBefore = blockBefore.timestamp

      await ethers.provider.send('evm_increaseTime', [sevenDays])
      await ethers.provider.send('evm_mine')

      const blockNumAfter = await ethers.provider.getBlockNumber()
      const blockAfter = await ethers.provider.getBlock(blockNumAfter)
      timestampAfter = blockAfter.timestamp

      await soundVerseToken.transfer(vesting.address, 1000000)
    })

    it('Claims for recipients and checks edge cases', async function () {
      const address1 = addr1.address
      const address2 = addr2.address

      await vesting.addMultipleRecipients(
        [address1, address2],
        [10000, 80000],
        [timestampBefore, timestampBefore],
      )
      // check for users with no claims
      await expect(await vesting.connect(addr3).claim())
        .to.emit(vesting, 'LogTokensClaimed')
        .withArgs(addr3.address, 0)
      // normal claim
      await expect(await vesting.connect(addr1).claim())
        .to.emit(vesting, 'LogTokensClaimed')
        .withArgs(addr1.address, 100000)

      // check for double claims
      await expect(vesting.connect(addr1).claim())
        .to.emit(vesting, 'LogTokensClaimed')
        .withArgs(addr1.address, 0)
    })

    it('Checks hasClaim() function ', async function () {
      const address1 = addr1.address
      const address2 = addr2.address

      await vesting.addMultipleRecipients(
        [address1, address2],
        [10000, 80000],
        [timestampBefore, timestampBefore],
      )

      // ideal cases
      await expect(await vesting.connect(addr2).hasClaim()).to.equal(800000)
    })

    it('Checks if pause freezes claims', async function () {
      await expect(
        await vesting.addRecipient(addr1.address, 100000, timestampBefore),
      )
        .to.emit(vesting, 'LogRecipientAdded')
        .withArgs(addr1.address, 100000)

      await vesting.vestingPause()
      await expect(vesting.connect(addr1).claim()).to.be.revertedWith(
        'Vesting is paused',
      )
    })
  })
})
