# NFT Staking

This project is a simple NFT staking contract that allows users to stake their NFTs and earn ERC20 rewards. The Staking Contract is UUPS Upgradeable.

## Contracts

1. **NFTStaking.sol:** This contract is the main staking contract that allows users to stake their NFTs and earn ERC20 rewards. This contract is UUPS upgradeable and uses the StakikngConfiguration contract to get the staking configuration.

2. **StakingConfiguration.sol:** This contract is used to store the staking configuration. It is used by the NFTStaking contract to get the staking configuration.

## Project Structure

```js
src/
└── interfaces/
    ├── INFTStaking.sol
    └── IStakingConfiguration.sol
    |
    ├── NFTStaking.sol
    |
    └── StakingConfiguration.sol
```

## Build

```bash
git clone https://github.com/Ericselvig/NFTStaking.git
cd NFTStaking
make build
```

## Deploy

```bash
make deploy-sepolia
```

**Note:** Before running the deploy command, make sure to set the variables in the `.env` file.
An `.env.example` file is provided for reference.

## Test

```bash
forge test
```

## Testnet Deployments

These contracts have been deployed on Ethereum Sepolia and verified on Etherscan.

| Contract             | Address                                    |
| -------------------- | ------------------------------------------ |
| NFTStaking (Proxy)   | 0xf72aEc482bB477110D6cD628c6AAA9AfefB9b9de |
| StakingConfiguration | 0x087c16038Ab34d3B25277337BF8D28a9a18060Da |
