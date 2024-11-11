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

    uint256 public constant CALL_GAS_LIMIT = 100_000;
    uint256 public constant VERIFICATION_GAS_LIMIT = 1_200_000;

    bytes32 private _PROXY_BYTECODE_HASH;
    ReferenceModularAccount public accountOwner;
    ReferenceModularAccount public account1;
    ReferenceModularAccount public account2;

    function run() external {
        console.log("Running ContractInteraction script");
        address accountImpl = vm.envOr("ACCOUNT_IMPL", address(0));
        _PROXY_BYTECODE_HASH = keccak256(
            abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(address(accountImpl), ""))
        );
        EntryPoint entryPoint = EntryPoint(payable(vm.envAddress("ENTRYPOINT")));
        AccountFactory factory = AccountFactory(payable(vm.envAddress("FACTORY")));
        SingleSignerValidationModule signerValidation = SingleSignerValidationModule(vm.envAddress("SINGLE_SIGNER_VALIDATION_MODULE"));
        Counter counter = Counter(payable(vm.envAddress("COUNTER")));

        console.log("signerValidataion: ", address(signerValidation));

        uint256 ownerKey = vm.envOr("PRIVATE_KEY", uint256(0));
        uint256 user1Key = vm.envOr("USER_KEY", uint256(0));
        uint256 user2Key = vm.envOr("USER2_KEY", uint256(0));
        address owner = vm.envAddress("OWNER");
        address user1 = vm.envAddress("USER_ADDRESS");
        address user2 = vm.envAddress("USER2_ADDRESS");

        accountOwner = factory.createAccount(owner, 100, 0);
        account1 = factory.createAccount(user1, 100, 0);
        account2 = factory.createAccount(user2, 100, 0);

        // print account id
        console.log("Account Owner ID: ", accountOwner.accountId());

        uint256 nonce = entryPoint.getNonce(address(accountOwner), 0);
        console.log("Account Owner Nonce: ", nonce);

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
        console.log("Before getUserOpHash", uint256(userOp.nonce));

        vm.startBroadcast();

        // Generate signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        console.log("UserOp Hash: ", uint256(userOpHash));
        
        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, userOpHash.toEthSignedMessageHash());
        
        vm.stopBroadcast();
    }

     // helper function to compress 2 gas values into a single bytes32
    function _encodeGas(uint256 g1, uint256 g2) internal pure returns (bytes32) {
        return bytes32(uint256((g1 << 128) + uint128(g2)));
    }
}

contract EntryPointInteraction is Script {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    uint256 public constant CALL_GAS_LIMIT = 100_000;
    uint256 public constant VERIFICATION_GAS_LIMIT = 1_200_000;

    bytes32 private _PROXY_BYTECODE_HASH;
    ReferenceModularAccount public accountOwner;
    ReferenceModularAccount public account1;
    ReferenceModularAccount public account2;

    function run() external {
        console.log("Running EntryInteraction script");
        EntryPoint entryPoint = EntryPoint(payable(vm.envAddress("ENTRYPOINT")));

        uint256 number = entryPoint.getNumber();
        console.log("EntryPoint number: ", number);

        vm.startBroadcast();
        entryPoint.increaseNumber();
        vm.stopBroadcast();

        number = entryPoint.getNumber();
        console.log("EntryPoint number after Boradcast: ", number);
    }

     // helper function to compress 2 gas values into a single bytes32
    function _encodeGas(uint256 g1, uint256 g2) internal pure returns (bytes32) {
        return bytes32(uint256((g1 << 128) + uint128(g2)));
    }
}

contract CounterInteraction is Script {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    uint256 public constant CALL_GAS_LIMIT = 100_000;
    uint256 public constant VERIFICATION_GAS_LIMIT = 1_200_000;

    bytes32 private _PROXY_BYTECODE_HASH;
    ReferenceModularAccount public accountOwner;
    ReferenceModularAccount public account1;
    ReferenceModularAccount public account2;

    function run() external {
        console.log("Running CounterInteraction script");
        Counter counter = Counter(payable(vm.envAddress("COUNTER")));

        uint256 ownerKey = vm.envOr("PRIVATE_KEY", uint256(0));
        uint256 user1Key = vm.envOr("USER_KEY", uint256(0));
        uint256 user2Key = vm.envOr("USER2_KEY", uint256(0));
        address owner = vm.envAddress("OWNER");
        address user1 = vm.envAddress("USER_ADDRESS");
        address user2 = vm.envAddress("USER2_ADDRESS");
        uint256 number = counter.number();
        console.log("Counter count: ", number);

        vm.startBroadcast();
        counter.increment();
        vm.stopBroadcast();
        
        number = counter.number();
        console.log("Counter count after Boradcast: ", number);
    }

     // helper function to compress 2 gas values into a single bytes32
    function _encodeGas(uint256 g1, uint256 g2) internal pure returns (bytes32) {
        return bytes32(uint256((g1 << 128) + uint128(g2)));
    }
}