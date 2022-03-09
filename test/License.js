const { constants } = require("@openzeppelin/test-helpers");
const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");

describe('License.contract', function () {

    let license;

    const firstTokenIdAmount = 50;
    const data = '0x';

    const DEFAULT_ADMIN_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000000';
    const PAUSER_ROLE = ethers.utils.solidityKeccak256(['string'], ['PAUSER_ROLE']);

    const uri = 'https://gateway.pinata.cloud/test.json';

    beforeEach(async function () {

        LicenseFactory = await ethers.getContractFactory("License");
        [signer, buyer] = await ethers.getSigners();
        license = await LicenseFactory.deploy();
    });

    describe('Initialization', function () {

        it('signer has the default admin role', async function () {
            expect(await license.getRoleMemberCount(DEFAULT_ADMIN_ROLE)).to.equal(1);
            expect(await license.getRoleMember(DEFAULT_ADMIN_ROLE, 0)).to.equal(signer.address);
        });

        it('signer has the pauser role', async function () {
            expect(await license.getRoleMemberCount(PAUSER_ROLE)).to.equal(1);
            expect(await license.getRoleMember(PAUSER_ROLE, 0)).to.equal(signer.address);
        });

        it('minter and pauser role admin is the default admin', async function () {
            expect(await license.getRoleAdmin(PAUSER_ROLE)).to.equal(DEFAULT_ADMIN_ROLE);
        });

    });

    describe('Minting licenses', function () {
        it('signer can mint tokens', async function () {
            const receipt = await license.mintLicenses(signer.address, buyer.address, uri, firstTokenIdAmount, data, { from: signer.address });

            expect(await license.uri(0)).to.equal(uri);

             // 2. TransferSingle(operator, from, to, id, amount);
            await expect(receipt)
                .to.emit(license, 'TransferSingle')
                .withArgs(signer.address, signer.address, buyer.address, 0, 1)

            expect(await license.balanceOf(buyer.address, 0)).to.equal(1);
        });

    });

    describe('Pausing', function () {
        it('signer can pause', async function () {
            const receipt = await license.pause({ from: signer.address });
            await expect(receipt)
                .to.emit(license, 'Paused')
                .withArgs(signer.address);

            expect(await license.paused()).to.equal(true);
        });

        it('signer can unpause', async function () {
            await license.pause({ from: signer.address });

            const receipt = await license.unpause({ from: signer.address });
            await expect(receipt)
                .to.emit(license, 'Unpaused')
                .withArgs(signer.address);

            expect(await license.paused()).to.equal(false);
        });

        it('cannot mint while paused', async function () {
            await license.pause({ from: signer.address });

            await expect(license.mintLicenses(signer.address, buyer.address, uri, firstTokenIdAmount, data, { from: signer.address })
            ).to.be.revertedWith("ERC1155Pausable: token transfer while paused");
        });

        it('buyer accounts cannot pause', async function () {
            await expect(license.connect(buyer).pause()).to.be.revertedWith("Must have pauser role to pause");
        });

        it('buyer accounts cannot unpause', async function () {
            await license.pause({ from: signer.address });

            await expect(license.connect(buyer).unpause({ from: buyer.address })).to.be.revertedWith("Must have pauser role to unpause");
        });
    });

});