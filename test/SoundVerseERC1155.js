const { constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");

describe.only('SoundVerseERC1155.contract', function () {

    let soundVerseERC1155;

    const firstTokenIdAmount = 50;
    const data = '0x';

    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const PAUSER_ROLE = ethers.utils.solidityKeccak256(['string'], ['PAUSER_ROLE']);

    const uri = 'https://gateway.pinata.cloud/test.json';

    beforeEach(async function () {

        SoundVerseERC1155Factory = await ethers.getContractFactory("SoundVerseERC1155");
        [deployer, other] = await ethers.getSigners();
        soundVerseERC1155 = await SoundVerseERC1155Factory.deploy();
    });

    describe('Initialization', function () {

        it('deployer has the default admin role', async function () {
            expect(await soundVerseERC1155.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.equal(1);
            expect(await soundVerseERC1155.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(deployer.address);
        });

        it('deployer has the pauser role', async function () {
            expect(await soundVerseERC1155.getRoleMemberCount(PAUSER_ROLE)).to.equal(1);
            expect(await soundVerseERC1155.getRoleMember(PAUSER_ROLE, 0)).to.equal(deployer.address);
        });

        it('minter and pauser role admin is the default admin', async function () {
            expect(await soundVerseERC1155.getRoleAdmin(PAUSER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
        });

    });

    describe('Minting licenses', function () {
        it('deployer can mint tokens', async function () {
            const receipt = await soundVerseERC1155.mintLicenses(other.address, uri, firstTokenIdAmount, data, { from: deployer.address });

            expect(await soundVerseERC1155.uri(0)).to.equal(uri);

            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(deployer.address, ZERO_ADDRESS, other.address, 0, firstTokenIdAmount)

            expect(await soundVerseERC1155.balanceOf(other.address, 0)).to.equal(firstTokenIdAmount);
        });

        it('other accounts can also mint tokens', async function () {
            const receipt = await soundVerseERC1155.connect(other).mintLicenses(other.address, uri, firstTokenIdAmount, data, { from: other.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(other.address, ZERO_ADDRESS, other.address, 0, firstTokenIdAmount)

            expect(await soundVerseERC1155.connect(other).balanceOf(other.address, 0)).to.equal(firstTokenIdAmount);
        });
    });

    describe('Pausing', function () {
        it('deployer can pause', async function () {
            const receipt = await soundVerseERC1155.pause({ from: deployer.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'Paused')
                .withArgs(deployer.address);

            expect(await soundVerseERC1155.paused()).to.equal(true);
        });

        it('deployer can unpause', async function () {
            await soundVerseERC1155.pause({ from: deployer.address });

            const receipt = await soundVerseERC1155.unpause({ from: deployer.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'Unpaused')
                .withArgs(deployer.address);

            expect(await soundVerseERC1155.paused()).to.equal(false);
        });

        it('cannot mint while paused', async function () {
            await soundVerseERC1155.pause({ from: deployer.address });

            await expect(soundVerseERC1155.mintLicenses(other.address, uri, firstTokenIdAmount, data, { from: deployer.address })
            ).to.be.revertedWith("ERC1155Pausable: token transfer while paused");
        });

        it('other accounts cannot pause', async function () {
            await expect(soundVerseERC1155.connect(other).pause()).to.be.revertedWith("Must have pauser role to pause");
        });

        it('other accounts cannot unpause', async function () {
            await soundVerseERC1155.pause({ from: deployer.address });

            await expect(soundVerseERC1155.connect(other).unpause({ from: other.address })).to.be.revertedWith("Must have pauser role to unpause");
        });
    });

});