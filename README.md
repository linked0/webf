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

## Source
Before testing, the next two codes should be commented out.
1. EntryPoint.sol innerHandleOp function
```
if (preGas < callGasLimit + mUserOp.verificationGasLimit + 5000) {
  assembly {
      mstore(0, INNER_OUT_OF_GAS)
      revert(0, 32)
  }
}
```

2. EntryPoint.sol handleOps function
```
_compensate(beneficiary, collected);
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

### Deploy & Use accounts
#### Counter
```shell
source .env; forge create src/Counter.sol:Counter --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY
```

Call for deployed contract
```
source .env; cast send $COUNTER_CONTRACT "increment()" --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY
```

To get number.
```
source .env; cast call $COUNTER_CONTRACT "number()(uint256)" --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY
```

If you have script for the calling, use the following command.
```
source .env; forge script script/CallCounter.s.sol:CallIncrease --rpc-url $RPC_URL_LOCALNET --broadcast
```

To generate revert,
```
source .env; forge script script/CallCounter.s.sol:GenerateRevert --rpc-url $RPC_URL_LOCALNET --broadcast
```
```

#### EntryPoint
`forge create` 쓰면 편한데 일단 만들어 놓은 `DeployEntryPont.s.sol` 사용.
```shell
source .env; forge script script/erc6900/DeployEntryPoint.s.sol:DeployEntryPoint --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY --broadcast 
```

#### SingleOwnerPlugin
`forge create` 쓰면 편한데 일단 만들어 놓은 `DeploySingleOwnerPlugin.s.sol` 사용.
```shell
source .env; forge script script/erc6900/DeploySingleOwnerPlugin.s.sol:DeploySingleOwnerPlugin --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY --broadcast 
```

#### Deploy ModularAccount and create account
`forge create` 쓰면 편한데 일단 만들어 놓은 `DeploySingleOwnerPlugin.s.sol` 사용.
```shell
source .env; forge script script/erc6900/DeployModularAccount.s.sol:DeployModularAccount --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY --broadcast 
```

Create account 1
```shell
source .env; forge script script/erc6900/CreateAccount.s.sol:CreateAccount --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY --broadcast -vvvv
```

Create account 2
```shell
source .env; forge script script/erc6900/CreateAccount.s.sol:CreateAccount2 --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY --broadcast -vvvv
```

#### EntryPoint basic operation
Contract Interaction
```shell
source .env; forge script script/erc6900/CallEntryPoint.s.sol:BasicUserOpInteract --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY --broadcast -vvvv
```

Send ETH
```shell
source .env; forge script script/erc6900/CallEntryPoint.s.sol:BasicUserOpEthSend --rpc-url $RPC_URL_LOCALNET --private-key $PRIVATE_KEY --broadcast -vvvv
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


## History
#### 24.11.22
- Error occured in running BasicUserOpInteract.
- Check following error. I think I should add storage variable for error log.
  ```
   [16773] 0xbcB08b651fB6319727c44eE093162764F9A4340A::handleOps([UserOperation({ sender: 0x8AbC9EDD763423979bbca4BB63636963d7cCb75B, nonce: 0, initCode: 0x, callData: 0xb61d27f600000000000000000000000064ff699b1caf990594d96bbe16ca77129b35736e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004d09de08a00000000000000000000000000000000000000000000000000000000, callGasLimit: 50000 [5e4], verificationGasLimit: 1200000 [1.2e6], preVerificationGas: 0, maxFeePerGas: 1, maxPriorityFeePerGas: 1, paymasterAndData: 0x, signature: 0x506a559c725b54783682498ec27b15fc7cf206a4d06246fbb09cd4e09a23916935266dece1417d6c481583f310a8f02adfa508271bf0416723c9b32f38043e691c })], beneficiary: [0x5c4d2bd3510C8B51eDB17766d3c96EC637326999])
    │   ├─ [0] 0x8AbC9EDD763423979bbca4BB63636963d7cCb75B::validateUserOp(UserOperation({ sender: 0x8AbC9EDD763423979bbca4BB63636963d7cCb75B, nonce: 0, initCode: 0x, callData: 0xb61d27f600000000000000000000000064ff699b1caf990594d96bbe16ca77129b35736e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004d09de08a00000000000000000000000000000000000000000000000000000000, callGasLimit: 50000 [5e4], verificationGasLimit: 1200000 [1.2e6], preVerificationGas: 0, maxFeePerGas: 1, maxPriorityFeePerGas: 1, paymasterAndData: 0x, signature: 0x506a559c725b54783682498ec27b15fc7cf206a4d06246fbb09cd4e09a23916935266dece1417d6c481583f310a8f02adfa508271bf0416723c9b32f38043e691c }), 0x286cea5f565418d5bc50c33fb165308dead48fba7fb05759a82671b698da4ff6, 1250000 [1.25e6])
    │   │   └─ ← [Stop] 
    │   └─ ← [Revert] EvmError: Revert
    └─ ← [Revert] EvmError: Revert
  ```