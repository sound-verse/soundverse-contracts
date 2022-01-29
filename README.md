# SoundVerse smart contracts

You will find on this project:
- SoundVerse ERC20 contract
- SoundVerse ERC721 contract 
- SoundVerse ERC1155 contract 
- SoundVerse Vesting contract 
- SoundVerse Market contract
- CommonUtils contract 
- PercentageUtils library

## Clone the repository
```git clone git@github.com:sound-verse/soundverse-contracts.git```

## Install dependencies
```npm install ethers hardhat @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers web3modal @openzeppelin/contracts ipfs-http-client axios```

## Compile smart contracts and run local node
```npm run prepare```

## Deploy CommonUtils contract
```npm run utils```

## Deploy rest of the contracts
```npm run dev```

## Run tests
```npx hardhat test```
