// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@eth-infinitism/account-abstraction/interfaces/PackedUserOperation.sol";
import {EntryPoint} from "@eth-infinitism/account-abstraction/core/EntryPoint.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {AccountFactory} from "../src/account/AccountFactory.sol";
import {ModuleManagerInternals} from "../src/account/ModuleManagerInternals.sol";
import {ReferenceModularAccount} from "../src/account/ReferenceModularAccount.sol";
import {SemiModularAccount} from "../src/account/SemiModularAccount.sol";
import {ExecutionManifest} from "../src/interfaces/IExecutionModule.sol";
import {Call} from "../src/interfaces/IModularAccount.sol";
import {ExecutionDataView} from "../src/interfaces/IModularAccountView.sol";
import {ModuleEntityLib} from "../src/libraries/ModuleEntityLib.sol";
import {ValidationConfigLib} from "../src/libraries/ValidationConfigLib.sol";
import {TokenReceiverModule} from "../src/modules/TokenReceiverModule.sol";
import {SingleSignerValidationModule} from "../src/modules/validation/SingleSignerValidationModule.sol";
import {Counter} from "../test/mocks/Counter.sol";

contract ContractInteraction is Script {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    bytes32 public salt = 0;
    uint256 public constant CALL_GAS_LIMIT = 100_000;
    uint256 public constant VERIFICATION_GAS_LIMIT = 1_200_000;
    bytes32 private _PROXY_BYTECODE_HASH;

    EntryPoint entryPoint;
    AccountFactory factory;
    ReferenceModularAccount accountImpl;
    SemiModularAccount semiAccount;
    SingleSignerValidationModule signerValidation;
    Counter counter;

    address owner;
    ReferenceModularAccount public accountOwner;
    ReferenceModularAccount public account1;
    ReferenceModularAccount public account2;

    function setUp() external {
        console.log("Running ContractInteraction script");
        uint256 ownerKey = vm.envOr("PRIVATE_KEY", uint256(0));
        uint256 user1Key = vm.envOr("USER_KEY", uint256(0));
        uint256 user2Key = vm.envOr("USER2_KEY", uint256(0));
        owner = vm.envAddress("OWNER");
        address user1 = vm.envAddress("USER_ADDRESS");
        address user2 = vm.envAddress("USER2_ADDRESS");

        entryPoint = new EntryPoint();
        accountImpl = new ReferenceModularAccount{salt: salt}(entryPoint);
        semiAccount = new SemiModularAccount{salt: 0}(entryPoint);
        signerValidation = new SingleSignerValidationModule{salt: salt}();
        factory = new AccountFactory(entryPoint, accountImpl, semiAccount, address(signerValidation), owner);
        counter = new Counter();

        console.log("entryPoint: ", address(entryPoint));
        console.log("signerValidataion: ", address(signerValidation));

        accountOwner = factory.createAccount(owner, 100, 0);
        account1 = factory.createAccount(user1, 100, 0);
        account2 = factory.createAccount(user2, 100, 0);

        // print account id
        console.log("Account Owner ID: ", accountOwner.accountId());
    }

    function test_getUserOpHash() external {
        uint256 nonce = entryPoint.getNonce(address(accountOwner), 0);

        // Make operation
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(owner),
            nonce: nonce,
            initCode: "",
            callData: abi.encodeCall(
                ReferenceModularAccount.execute, (address(counter), 0, abi.encodeCall(counter.increment, ()))
            ),
            accountGasLimits: _encodeGas(VERIFICATION_GAS_LIMIT, CALL_GAS_LIMIT),
            preVerificationGas: 0,
            gasFees: _encodeGas(1, 1),
            paymasterAndData: "",
            signature: ""
        });

        // Generate signature
        console.log("Before getUserOpHash: ", userOp.nonce);
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        console.log("UserOp Hash: ", uint256(userOpHash));
    }

     // helper function to compress 2 gas values into a single bytes32
    function _encodeGas(uint256 g1, uint256 g2) internal pure returns (bytes32) {
        return bytes32(uint256((g1 << 128) + uint128(g2)));
    }
}