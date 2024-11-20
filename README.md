# webf Foundry Example Project
## Folder Summary

### Folders for ERC6900 in src
- account
- helpers
- interfaces
- libraries
- plugins
- samples

### Folders for ERC6900 in test
- account
- comparison
- libraries
- mocks
- plugin
- samples
- utils

## How to use Foundry
### Instal submodule
```
forge install foundry-rs/forge-std
forge install https://github.com/eth-infinitism/account-abstraction
forge install https://github.com/OpenZeppelin/openzeppelin-contracts
```

### Remapping dependencies
```
forge remappings
```

## Setup
### Init dependencies
If you have .gitmodules file, just do the following.
```
git submodule update --init 
```
### Build

```shell
forge build
```

### Test

```shell
forge test
```

If you want only one file, just run the following.
```
forge test --match-path test/Counter.t.sol
```

If you want only one function, just run the following.
```
forge test --match-test test_Increment
```

If you want only one contract, just run the following.
```
forge test --match-contract CounterTest
```

### Clean
```
forge clean
```

### Deploy

```shell
source .env
forge create src/Counter.sol:Counter --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY
```

### Call for deployed contract
```
cast send $COUNTER_CONTRACT "increment()" --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY
```

To get number.
```
cast call $COUNTER_CONTRACT "number()(uint256)" --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY
```

If you have script for the calling, use the following command.
```
forge script script/CounterIncrease.s.sol:CallIncrease --rpc-url $RPC_URL_LOCALNET --broadcast
```
### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil

```shell
anvil
```



### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Documentation

https://book.getfoundry.sh/
