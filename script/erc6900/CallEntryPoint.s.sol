// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "@eth-infinitism/account-abstraction/core/EntryPoint.sol";
import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";
import {SingleOwnerPlugin} from "@erc6900/plugins/owner/SingleOwnerPlugin.sol";
import {UpgradeableModularAccount} from "@erc6900/account/UpgradeableModularAccount.sol";
import {console} from "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EntryPoint} from "@eth-infinitism/account-abstraction/core/EntryPoint.sol";
import {UserOperation} from "@eth-infinitism/account-abstraction/interfaces/UserOperation.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Counter} from "@erc6900/Counter.sol";

contract UserOpSendEth is Script {
    using ECDSA for bytes32;

    bytes32 private immutable _PROXY_BYTECODE_HASH;
    uint256 public constant CALL_GAS_LIMIT = 50000;
    uint256 public constant VERIFICATION_GAS_LIMIT = 120000;

    address entryPointAddr;
    EntryPoint entryPoint;
    Counter public counter;

    address public owner1;
    uint256 public owner1Key;
    uint256 salt1;
    address public account1;

    address public owner2;
    uint256 public owner2Key;
    uint256 salt2;
    address public account2;

    address payable recipient;
    address payable beneficiary;

    constructor() {
        address modularAccount = vm.envAddress(
            "UPGRADEABLE_MODULAR_ACCOUNT_ADDRESS"
        );
        _PROXY_BYTECODE_HASH = keccak256(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(address(modularAccount), "")
            )
        );
    }

    function run() external {
        entryPointAddr = vm.envAddress("ENTRYPOINT_CONTRACT_ADDRESS");
        entryPoint = EntryPoint(payable(entryPointAddr));
        
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        counter = Counter(vm.envAddress("COUNTER_CONTRACT"));
        owner1Key = vm.envUint("OWNER1_KEY");
        account1 = vm.envAddress("OWNER1_ACCOUNT");
        console.log("ownerAccount1:", account1);

        recipient = payable(vm.envAddress("RECIPIENT"));
        beneficiary = payable(vm.envAddress("BENEFICIARY"));
        console.log("beneficiary balance:", beneficiary.balance);
        console.log("recipient:", recipient, "beneficiary:", beneficiary);

        uint nonce = entryPoint.getNonce(account1, 0);
        console.log("nonce:", nonce);
        UserOperation memory userOp = UserOperation({
            sender: account1,
            nonce: nonce,
            initCode: "",
            callData: abi.encodeCall(
                UpgradeableModularAccount.execute, (recipient, 1 ether, "")
                ),
            callGasLimit: CALL_GAS_LIMIT,
            verificationGasLimit: VERIFICATION_GAS_LIMIT,
            preVerificationGas: 10,  // gwei
            maxPriorityFeePerGas: 20,  // gwei
            maxFeePerGas: 10,  // gwei
            paymasterAndData: "",
            signature: ""
        });

        // Generate signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1Key, userOpHash.toEthSignedMessageHash());
        userOp.signature = abi.encodePacked(r, s, v);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        vm.startBroadcast(privateKey);
        entryPoint.handleOps(userOps, beneficiary);
        vm.stopBroadcast();
        console.log("beneficiary balance at end:", beneficiary.balance);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(getSalt(owner, salt), _PROXY_BYTECODE_HASH);
    }

    function getSalt(
        address owner,
        uint256 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, salt));
    }
}

contract UserOpIncrement is Script {
    using ECDSA for bytes32;

    bytes32 private immutable _PROXY_BYTECODE_HASH;
    uint256 public constant CALL_GAS_LIMIT = 50000;
    uint256 public constant VERIFICATION_GAS_LIMIT = 120000;

    address entryPointAddr;
    EntryPoint entryPoint;
    Counter public counter;

    address public owner1;
    uint256 public owner1Key;
    uint256 salt1;
    address public account1;

    address public owner2;
    uint256 public owner2Key;
    uint256 salt2;
    address public account2;

    address payable recipient;
    address payable beneficiary;

    constructor() {
        address modularAccount = vm.envAddress(
            "UPGRADEABLE_MODULAR_ACCOUNT_ADDRESS"
        );
        _PROXY_BYTECODE_HASH = keccak256(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(address(modularAccount), "")
            )
        );
    }

    function run() external returns (uint256) {
        console.log("ENTRYPOINT_CONTRACT_ADDRESS", vm.envAddress("ENTRYPOINT_CONTRACT_ADDRESS"));
        entryPointAddr = vm.envAddress("ENTRYPOINT_CONTRACT_ADDRESS");
        entryPoint = EntryPoint(payable(entryPointAddr));
        
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        counter = Counter(vm.envAddress("COUNTER_CONTRACT"));

        owner1 = vm.envAddress("OWNER1");
        owner1Key = vm.envUint("OWNER1_KEY");
        salt1 = vm.envUint("SALT");

        // owner2 = vm.envAddress("OWNER2");
        // owner2Key = vm.envUint("OWNER2_KEY");
        // salt2 = vm.envUint("OWNER2_SALT");
        // account2 = UpgradeableModularAccount(payable(this.getAddress(owner2, salt2)));

        address accountComputed = Create2.computeAddress(
            getSalt(owner1, salt1),
            _PROXY_BYTECODE_HASH
        );
        console.log("accountComputed:", accountComputed);
        account1 = vm.envAddress("OWNER1_ACCOUNT");
        account2 = Create2.computeAddress(
            getSalt(owner2, salt2),
            _PROXY_BYTECODE_HASH
        );

        console.log("ownerAccount1:", account1);
        console.log("ownerAccount2:", account2);

        recipient = payable(vm.envAddress("RECIPIENT"));
        beneficiary = payable(vm.envAddress("BENEFICIARY"));
        console.log("recipient:", recipient, "beneficiary:", beneficiary);

        uint nonce = entryPoint.getNonce(account1, 0);
        console.log("nonce:", nonce);

        UserOperation memory userOp = UserOperation({
            sender: account1,
            nonce: nonce,
            initCode: "",
            callData: abi.encodeCall(
                UpgradeableModularAccount.execute, (address(counter), 0, abi.encodeCall(counter.increment, ()))
                ),
            callGasLimit: CALL_GAS_LIMIT,
            verificationGasLimit: VERIFICATION_GAS_LIMIT,
            preVerificationGas: 0,
            maxPriorityFeePerGas: 2 gwei,
            maxFeePerGas: block.basefee + 2 gwei,
            paymasterAndData: "",
            signature: ""
        });

        // Generate signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1Key, userOpHash.toEthSignedMessageHash());
        userOp.signature = abi.encodePacked(r, s, v);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        vm.startBroadcast(privateKey);
        entryPoint.handleOps(userOps, beneficiary);
        vm.stopBroadcast();

        return counter.number();
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(getSalt(owner, salt), _PROXY_BYTECODE_HASH);
    }

    function getSalt(
        address owner,
        uint256 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, salt));
    }

    function toHexString(bytes32 data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 byteValue = uint8(data[i]);
            str[i * 2] = alphabet[byteValue >> 4];
            str[1 + i * 2] = alphabet[byteValue & 0x0f];
        }
        return string(abi.encodePacked("0x", str));
    }

    function addressToHex(address addr) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes20 data = bytes20(addr);
        bytes memory str = new bytes(42); // "0x" + 40 characters for the address
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(data[i] >> 4)]; // Extract the high nibble
            str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)]; // Extract the low nibble
        }
        return string(str);
    }
}