const { constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;

const { expect } = require("chai");

describe('SoundVerseERC1155.contract', function () {

    let soundVerseERC1155;

    const firstTokenId = 845;
    const firstTokenIdAmount = 5000;

    const secondTokenId = 48324;
    const secondTokenIdAmount = 77875;

    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const MINTER_ROLE = ethers.utils.solidityKeccak256(['string'], ['MINTER_ROLE']);
    const PAUSER_ROLE = ethers.utils.solidityKeccak256(['string'], ['PAUSER_ROLE']);

    const uri = 'https://gateway.pinata.cloud/ipfs/{id}';

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
            const receipt = await soundVerseERC1155.mint(other.address, firstTokenId, firstTokenIdAmount, '0x', { from: deployer.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(deployer.address, ZERO_ADDRESS, other.address, firstTokenId, firstTokenIdAmount)

            expect(await soundVerseERC1155.balanceOf(other.address, firstTokenId)).to.equal(firstTokenIdAmount);
        });

        it('other accounts can also mint tokens', async function () {
            const receipt = await soundVerseERC1155.connect(other).mint(other.address, firstTokenId, firstTokenIdAmount, '0x', { from: other.address });
            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(other.address, ZERO_ADDRESS, other.address, firstTokenId, firstTokenIdAmount)

            expect(await soundVerseERC1155.connect(other).balanceOf(other.address, firstTokenId)).to.equal(firstTokenIdAmount);
        });
    });

    describe('batched minting', function () {
        it('deployer can batch mint tokens', async function () {
            const receipt = await soundVerseERC1155.mintBatch(
                other.address, [firstTokenId, secondTokenId], [firstTokenIdAmount, secondTokenIdAmount], '0x', { from: deployer.address },
            );

            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferBatch')
                .withArgs(deployer.address, ZERO_ADDRESS, other.address, [firstTokenId, secondTokenId], [firstTokenIdAmount, secondTokenIdAmount]);

            expect(await soundVerseERC1155.balanceOf(other.address, firstTokenId)).to.equal(firstTokenIdAmount);
        });

        it('other accounts can also batch mint tokens', async function () {
            const receipt = await soundVerseERC1155.connect(other).mintBatch(
                other.address, [firstTokenId, secondTokenId], [firstTokenIdAmount, secondTokenIdAmount], '0x', { from: other.address },
            );

            await expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferBatch')
                .withArgs(other.address, ZERO_ADDRESS, other.address, [firstTokenId, secondTokenId], [firstTokenIdAmount, secondTokenIdAmount]);

            expect(await soundVerseERC1155.balanceOf(other.address, firstTokenId)).to.equal(firstTokenIdAmount);
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

            await expect(soundVerseERC1155.mint(other.address, firstTokenId, firstTokenIdAmount, '0x', { from: deployer.address })
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
            await soundVerseERC1155.mint(other.address, firstTokenId, firstTokenIdAmount, '0x', { from: deployer.address });

            const receipt = await soundVerseERC1155.connect(other).burn(other.address, firstTokenId, 4999, { from: other.address });
            expect(receipt)
                .to.emit(soundVerseERC1155, 'TransferSingle')
                .withArgs(other.address, other.address, ZERO_ADDRESS, firstTokenId, 4999);

            expect(await soundVerseERC1155.balanceOf(other.address, firstTokenId)).to.equal(1);
        });
    });
});