// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "@eth-infinitism/account-abstraction/core/EntryPoint.sol";
import {SingleOwnerPlugin} from "@erc6900/plugins/owner/SingleOwnerPlugin.sol";
import {UpgradeableModularAccount} from "@erc6900/account/UpgradeableModularAccount.sol";
import {console} from "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EntryPoint} from "@eth-infinitism/account-abstraction/core/EntryPoint.sol";
import {UserOperation} from "@eth-infinitism/account-abstraction/interfaces/UserOperation.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Counter} from "@erc6900/Counter.sol";

contract BasicUserOpInteract is Script {
    using ECDSA for bytes32;

    bytes32 private immutable _PROXY_BYTECODE_HASH;
    uint256 public constant CALL_GAS_LIMIT = 50000;
    uint256 public constant VERIFICATION_GAS_LIMIT = 1200000;

    address entryPointAddr;
    EntryPoint entryPoint;
    Counter public counter;

    address public owner1;
    uint256 public owner1Key;
    uint256 salt1;
    UpgradeableModularAccount public account1;

    address public owner2;
    uint256 public owner2Key;
    uint256 salt2;
    UpgradeableModularAccount public account2;

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

    function run() external returns (uint) {
        entryPointAddr = vm.envAddress("ENTRYPOINT_CONTRACT_ADDRESS");
        entryPoint = EntryPoint(payable(entryPointAddr));
        
        counter = Counter(vm.envAddress("COUNTER_CONTRACT"));

        owner1 = vm.envAddress("OWNER1");
        owner1Key = vm.envUint("OWNER1_KEY");
        account1 = UpgradeableModularAccount(payable(vm.envAddress("OWNER1_ACCOUNT")));
        salt1 = vm.envUint("SALT");
        console.log("owner:", owner1);
        console.log("ownerKey:", Strings.toHexString(owner1Key));
        console.log("ownerAccount:", address(account1));
        console.log("salt1:", salt1);

        owner2 = vm.envAddress("OWNER2");
        owner2Key = vm.envUint("OWNER2_KEY");
        salt2 = vm.envUint("OWNER2_SALT");
        account2 = UpgradeableModularAccount(payable(this.getAddress(owner2, salt2)));

        address addr = Create2.computeAddress(
            getSalt(owner1, salt1),
            _PROXY_BYTECODE_HASH
        );
        address addr2 = Create2.computeAddress(
            getSalt(owner2, salt2),
            _PROXY_BYTECODE_HASH
        );
        if (addr != address(account1) || addr2 != address(account2)) { 
            console.log("accounts are mismatch");
            return 0;
        }

        recipient = payable(makeAddr("recipient"));
        beneficiary = payable(makeAddr("beneficiary"));
        console.log("recipient:", recipient, "beneficiary:", beneficiary);

        vm.startBroadcast();
        UserOperation memory userOp = UserOperation({
            sender: address(account2),
            nonce: 0,
            initCode: "",
            callData: abi.encodeCall(
                UpgradeableModularAccount.execute, (address(counter), 0, abi.encodeCall(counter.increment, ()))
                ),
            callGasLimit: CALL_GAS_LIMIT,
            verificationGasLimit: VERIFICATION_GAS_LIMIT,
            preVerificationGas: 0,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: "",
            signature: ""
        });

        // Generate signature
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner2Key, userOpHash.toEthSignedMessageHash());
        userOp.signature = abi.encodePacked(r, s, v);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

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
}
