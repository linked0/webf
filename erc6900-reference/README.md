# ERC-6900 Reference Implementation

Reference implementation for [ERC-6900](https://eips.ethereum.org/EIPS/eip-6900).

The implementation includes an upgradable modular account with 5 modules (`SingleSignerValidationModule`, `TokenReceiverModule`, `AllowlistModule`, `ERC20TokenLimitModule`, and `NativeTokenLimitModule`). It is compliant with the latest version of ERC-6900.

## Install
```
forge install foundry-rs/forge-std@v1.5.3 --no-commit
forge install eth-infinitism/account-abstraction --no-commit
forge install vectorized/solady --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```
## Test
Test one file
```
forge test --match-path test/account/UpgradeableModularAccount.t.sol
```

Test one function
```
forge test -vvvv --match-test test_jay_basicUserOp

forge test -vvvv --match-path test/account/UpgradeableModularAccount.t.sol --match-test test_jay_basicUserOp
```

## Deploy
```
forge script script/Deploy.s.sol --private-key 0x58984b2bf6f0f3de4f38290ed3c541ac27bac384b378073ab133af8b314a1887 --rpc-url http://localhost:8545 --broadcast
```

#### 24.11.06 Deployed
First, it will fail because the .env file lacks addresses for the contracts, and the script compares the expected address in .env with the deployed addresses. So, you should first run the script to obtain the expected addresses, which will then be written in .env.

```
# Factory owner capable only of managing stake
OWNER=0x1811DfdE14b2e9aBAF948079E8962d200E71aCFD
# EP 0.7 address
ENTRYPOINT=0xaCA7A4F5E1111572C3764F9E5B4072AfA95593aB

# Create2 expected addresses of the contracts.
# When running for the first time, the error message will contain the expected addresses.
ACCOUNT_IMPL=0xDf24AE006565c66a5141653366A2e1AE6aB6D38E
SINGLE_SIGNER_VALIDATION_MODULE=0x402466140cB7D09eF2e0b277165e2Ae214c2D6D0
FACTORY=0xe9C4498d0e5701bDdf4F0832D4C1810f2af8aE7C
```

## Important callouts

- **Not audited and SHOULD NOT be used in production**.
- Not optimized in both deployments and execution. We’ve explicitly removed some optimizations in favor of clarity.

## Development

Anyone is welcome to submit feedback and/or PRs to improve code.

### Testing

The default Foundry profile can be used to compile (without IR) and test the entire project. The default profile should be used when generating coverage and debugging.

```bash
forge build
forge test -vvv
```

Since IR compilation generates different bytecode, it's useful to test against the contracts compiled via IR. Since compiling the entire project (including the test suite) takes a long time, special profiles can be used to precompile just the source contracts, and have the tests deploy the relevant contracts using those artifacts.

```bash
FOUNDRY_PROFILE=optimized-build forge build
FOUNDRY_PROFILE=optimized-test forge test -vvv
```

## Integration testing

The reference implementation provides a sample factory and deploy script for the factory, account implementation, and the demo validation module `SingleSignerValidationModule`. This is not audited nor intended for production use. Limitations set by the GPLv3 license apply.

To run this script, provide appropriate values in a `.env` file based on the `.env.example` template, then run:

```bash
forge script script/Deploy.s.sol <wallet options> -r <rpc_url> --broadcast
```

Where `<wallet_options>` specifies a way to sign the deployment transaction (see [here](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---raw)) and `<rpc_url>` specifies an RPC for the network you are deploying on.
