const { constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");

describe('SoundVerseERC1155.contract', function () {

    let soundVerseERC1155;

    const firstTokenIdAmount = 50;
    const data = '0x';

    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const PAUSER_ROLE = ethers.utils.solidityKeccak256(['string'], ['PAUSER_ROLE']);

    const uri = 'https://gateway.pinata.cloud/test.json';

    beforeEach(async function () {

        SoundVerseERC1155Factory = await ethers.getContractFactory("SoundVerseERC1155");
        [signer, buyer] = await ethers.getSigners();
        soundVerseERC1155 = await SoundVerseERC1155Factory.deploy();
    });

    describe('Initialization', function () {

        it('signer has the default admin role', async function () {
            expect(await soundVerseERC1155.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.equal(1);
            expect(await soundVerseERC1155.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(signer.address);
        });

        it('signer has the pauser role', async function () {
            expect(await soundVerseERC1155.getRoleMemberCount(PAUSER_ROLE)).to.equal(1);
            expect(await soundVerseERC1155.getRoleMember(PAUSER_ROLE, 0)).to.equal(signer.address);
        });

        it('minter and pauser role admin is the default admin', async function () {
            expect(await soundVerseERC1155.getRoleAdmin(PAUSER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
        });

    });

    describe('Minting licenses', function () {
        it('signer can mint tokens', async function () {
            const receipt = await soundVerseERC1155.mintLicenses(signer.address, buyer.address, uri, firstTokenIdAmount, data, { from: signer.address });

            expect(await soundVerseERC1155.uri(0)).to.equal(uri);

             // 2. TransferSingle(operator, from, to, id, amount);
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(signer.address, signer.address, buyer.address, 0, 1)

            expect(await soundVerseERC1155.balanceOf(buyer.address, 0)).to.equal(1);
        });

    });

    describe('Pausing', function () {
        it('signer can pause', async function () {
            const receipt = await soundVerseERC1155.pause({ from: signer.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'Paused')
                .withArgs(signer.address);

            expect(await soundVerseERC1155.paused()).to.equal(true);
        });

        it('signer can unpause', async function () {
            await soundVerseERC1155.pause({ from: signer.address });

            const receipt = await soundVerseERC1155.unpause({ from: signer.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'Unpaused')
                .withArgs(signer.address);

            expect(await soundVerseERC1155.paused()).to.equal(false);
        });

        it('cannot mint while paused', async function () {
            await soundVerseERC1155.pause({ from: signer.address });

            await expect(soundVerseERC1155.mintLicenses(signer.address, buyer.address, uri, firstTokenIdAmount, data, { from: signer.address })
            ).to.be.revertedWith("ERC1155Pausable: token transfer while paused");
        });

        it('buyer accounts cannot pause', async function () {
            await expect(soundVerseERC1155.connect(buyer).pause()).to.be.revertedWith("Must have pauser role to pause");
        });

        it('buyer accounts cannot unpause', async function () {
            await soundVerseERC1155.pause({ from: signer.address });

            await expect(soundVerseERC1155.connect(buyer).unpause({ from: buyer.address })).to.be.revertedWith("Must have pauser role to unpause");
        });
    });

});