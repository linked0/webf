-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make fund ARGS=\"--network sepolia\""

all: clean install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(PRIVATE_KEY) --broadcast

deploy:
	forge script script/Deploy.s.sol:DeployScript $(NETWORK_ARGS)

deploy-counter:
	forge script script/DeployCounter.s.sol:DeployScript $(NETWORK_ARGS)

# For deploying Interactions.s.sol:FundFundMe as well as for Interactions.s.sol:WithdrawFundMe we have to include a sender's address `--sender <ADDRESS>`
SENDER_ADDRESS := 0x1811DfdE14b2e9aBAF948079E8962d200E71aCFD

interact:
	forge script script/Interactions.s.sol:ContractInteraction $(NETWORK_ARGS)

interact-counter:
	forge script script/Interactions.s.sol:CounterInteraction $(NETWORK_ARGS)
