var LiniftyNFT = artifacts.require("LiniftyNFT");

contract('LiniftyNFT', function (accounts) {
    var nftInstance;
    var tokenURI = "test-tokenuri.com/test";

    it('initializes the contract with correct values', function () {
        return LiniftyNFT.deployed().then(function (instance) {
            nftInstance = instance;
            return nftInstance.address;
        }).then(function (address) {
            assert.notEqual(address, 0x0, 'has contract address');
        });
    });

    it('creates unpublished item and returns the tokenId', function (){
        return LiniftyNFT.deployed().then(function (instance) {
            nftInstance = instance;
            return nftInstance.createUnpublishedItem.call(tokenURI);
        }).then(function (id){
            assert.equal(id, 1, 'has correct token id');
        });
    });


});