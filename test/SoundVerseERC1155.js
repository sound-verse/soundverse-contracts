const { BN, constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

describe('SoundVerseERC1155.contract', function () {

    let soundVerseERC1155;

    const firstTokenId = new BN('845');
    const firstTokenIdAmount = new BN('5000');

    const secondTokenId = new BN('48324');
    const secondTokenIdAmount = new BN('77875');

    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const MINTER_ROLE = ethers.utils.solidityKeccak256(['string'], ['MINTER_ROLE']);
    const PAUSER_ROLE = ethers.utils.solidityKeccak256(['string'], ['PAUSER_ROLE']);

    const uri = 'https://token.com';

    beforeEach(async function () {
        SoundVerseERC1155Factory = await ethers.getContractFactory("SoundVerseERC1155");
        [deployer, other] = await ethers.getSigners();
        soundVerseERC1155 = await SoundVerseERC1155Factory.deploy(uri);
    });

    it('deployer has the default admin role', async function () {
        expect(await soundVerseERC1155.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.equal(1);
        expect(await soundVerseERC1155.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(deployer.address);
    });

    it('deployer has the minter role', async function () {
        expect(await soundVerseERC1155.getRoleMemberCount(MINTER_ROLE)).to.equal(1);
        expect(await soundVerseERC1155.getRoleMember(MINTER_ROLE, 0)).to.equal(deployer.address);
    });

    it('deployer has the pauser role', async function () {
        expect(await soundVerseERC1155.getRoleMemberCount(PAUSER_ROLE)).to.equal(1);
        expect(await soundVerseERC1155.getRoleMember(PAUSER_ROLE, 0)).to.equal(deployer.address);
    });

    it('minter and pauser role admin is the default admin', async function () {
        expect(await soundVerseERC1155.getRoleAdmin(MINTER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
        expect(await soundVerseERC1155.getRoleAdmin(PAUSER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
    });

    describe('minting', function () {
        it('deployer can mint tokens', async function () {
            const receipt = await soundVerseERC1155.mint(other.address, firstTokenId.toString(), firstTokenIdAmount.toString(), '0x', { from: deployer.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(deployer.address, ZERO_ADDRESS, other.address, firstTokenId.toString(), firstTokenIdAmount.toString())

            expect(await soundVerseERC1155.balanceOf(other.address, firstTokenId.toString())).to.equal(firstTokenIdAmount.toString());
        });

        it('other accounts cannot mint tokens', async function () {
            await expect(soundVerseERC1155.connect(other).mint(other.address, firstTokenId.toString(), firstTokenIdAmount.toString(), '0x'))
                .to.be.revertedWith("ERC1155PresetMinterPauser: must have minter role to mint")
        });
    });

    describe('batched minting', function () {
        it('deployer can batch mint tokens', async function () {
            const receipt = await soundVerseERC1155.mintBatch(
                other.address, [firstTokenId.toString(), secondTokenId.toString()], [firstTokenIdAmount.toString(), secondTokenIdAmount.toString()], '0x', { from: deployer.address },
            );

            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferBatch')
                .withArgs(deployer.address, ZERO_ADDRESS, other.address, [firstTokenId.toString(), secondTokenId.toString()], [firstTokenIdAmount.toString(), secondTokenIdAmount.toString()]);

            expect(await soundVerseERC1155.balanceOf(other.address, firstTokenId.toString())).to.equal(firstTokenIdAmount.toString());
        });

        it('other accounts cannot batch mint tokens', async function () {
            await expect(soundVerseERC1155.connect(other).mintBatch(
                other.address, [firstTokenId.toString(), secondTokenId.toString()], [firstTokenIdAmount.toString(), secondTokenIdAmount.toString()], '0x', { from: other.address }
            )).to.be.revertedWith("ERC1155PresetMinterPauser: must have minter role to mint");
        });

    });

    describe('pausing', function () {
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

            await expect(soundVerseERC1155.mint(other.address, firstTokenId.toString(), firstTokenIdAmount.toString(), '0x', { from: deployer.address })
            ).to.be.revertedWith("ERC1155Pausable: token transfer while paused");
        });

        it('other accounts cannot pause', async function () {
            await expect(soundVerseERC1155.connect(other).pause()).to.be.revertedWith("ERC1155PresetMinterPauser: must have pauser role to pause");
        });

        it('other accounts cannot unpause', async function () {
            await soundVerseERC1155.pause({ from: deployer.address });

            await expect(soundVerseERC1155.connect(other).unpause({ from: other.address })).to.be.revertedWith("ERC1155PresetMinterPauser: must have pauser role to unpause");
        });
    });

    describe('burning', function () {
        it('holders can burn their tokens', async function () {
            await soundVerseERC1155.mint(other.address, firstTokenId.toString(), firstTokenIdAmount.toString(), '0x', { from: deployer.address });

            const receipt = await soundVerseERC1155.connect(other).burn(other.address, firstTokenId.toString(), firstTokenIdAmount.subn(1).toString(), { from: other.address });
            expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(other.address, other.address, ZERO_ADDRESS, firstTokenId.toString(), firstTokenIdAmount.subn(1).toString());

            expect(await soundVerseERC1155.balanceOf(other.address, firstTokenId.toString())).to.equal(1);
        });
    });
});