-include .env

build:; forge build
compile:; forge compile

deploy-sepolia:
	forge script script/DeployNFTStaking.s.sol --rpc-url $(SEPOLIA_API_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv