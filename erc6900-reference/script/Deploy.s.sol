// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {EntryPoint} from "@eth-infinitism/account-abstraction/core/EntryPoint.sol";
import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";
import {Script, console} from "forge-std/Script.sol";

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {AccountFactory} from "../src/account/AccountFactory.sol";

import {ReferenceModularAccount} from "../src/account/ReferenceModularAccount.sol";
import {SemiModularAccount} from "../src/account/SemiModularAccount.sol";
import {SingleSignerValidationModule} from "../src/modules/validation/SingleSignerValidationModule.sol";

contract DeployScript is Script {
    bool private success = true;
    address private ACCOUNT_IMPL = address(0);
    address private SINGLE_SIGNER_VALIDATION_MODULE = address(0);
    address private FACTORY = address(0);
    address private SMA_IMPL = address(0);

    IEntryPoint public entryPoint;

    address public owner = vm.envAddress("OWNER");

    address public accountImpl = vm.envOr("ACCOUNT_IMPL", address(0));
    address public semiModularAccountImpl = vm.envOr("SMA_IMPL", address(0));
    address public factory = vm.envOr("FACTORY", address(0));
    address public singleSignerValidationModule = vm.envOr("SINGLE_SIGNER_VALIDATION_MODULE", address(0));

    bytes32 public accountImplSalt = bytes32(vm.envOr("ACCOUNT_IMPL_SALT", uint256(0)));
    bytes32 public semiModularAccountImplSalt = bytes32(vm.envOr("SMA_IMPL_SALT", uint256(0)));
    bytes32 public factorySalt = bytes32(vm.envOr("FACTORY_SALT", uint256(0)));
    bytes32 public singleSignerValidationModuleSalt =
        bytes32(vm.envOr("SINGLE_SIGNER_VALIDATION_MODULE_SALT", uint256(0)));

    uint256 public requiredStakeAmount = vm.envOr("STAKE_AMOUNT", uint256(0.1 ether));
    uint256 public requiredUnstakeDelay = vm.envOr("UNSTAKE_DELAY", uint256(1 days));

    function run() public {
        console.log("******** Deploying ERC-6900 Reference Implementation ********");
        console.log("Chain: ", block.chainid);
        console.log("Factory owner: ", owner);

        vm.startBroadcast();
        _deployEntryPoint();
        _deployAccountImpl(accountImplSalt, accountImpl);
        _deploySemiModularAccountImpl(semiModularAccountImplSalt, semiModularAccountImpl);
        _deploySingleSignerValidation(singleSignerValidationModuleSalt, singleSignerValidationModule);
        _deployAccountFactory(factorySalt, factory);
        _addStakeForFactory(uint32(requiredUnstakeDelay), requiredStakeAmount);

        if (success) {
            console.log("ENTRYPOINT=", address(entryPoint));
            console.log("ACCOUNT_IMPL=", ACCOUNT_IMPL);
            console.log("SINGLE_SIGNER_VALIDATION_MODULE=", SINGLE_SIGNER_VALIDATION_MODULE);
            console.log("FACTORY=", FACTORY);
            console.log("SMA_IMPL=", SMA_IMPL);
        }
        else {
            revert();
        }
        vm.stopBroadcast();
    }

    function _deployEntryPoint() internal {
        console.log(string.concat("Deploying EntryPoint"));
        if(vm.envOr("ENTRYPOINT", address(0)) != address(0)) {
            entryPoint = IEntryPoint(payable(vm.envAddress("ENTRYPOINT")));
        } else {
            console.log("No entrypoint provided, deploying new one");
            entryPoint = new EntryPoint();
        }
        console.log("Deployed EntryPoint at: ", address(entryPoint));
    }

    function _deployAccountImpl(bytes32 salt, address expected) internal {
        console.log(string.concat("Deploying AccountImpl with salt: ", vm.toString(salt)));

        address addr = Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(type(ReferenceModularAccount).creationCode, abi.encode(entryPoint))),
            CREATE2_FACTORY
        );
        if (expected != address(0) && addr != expected) {
            console.log("Expected address mismatch");
            console.log("Expected: ", expected);
            console.log("Actual: ", addr);
            success = false;
            return;
        }

        if (expected == address(0) || addr.code.length == 0) {
            console.log("No code found at expected address, deploying...");
            ReferenceModularAccount deployed = new ReferenceModularAccount{salt: salt}(entryPoint);

            if (expected != address(0) && address(deployed) != expected) {
                console.log("Deployed address mismatch");
                console.log("Expected: ", expected);
                console.log("Deployed: ", address(deployed));
                success = false;
                return;
            }
            ACCOUNT_IMPL = address(deployed);
            console.log("Deployed AccountImpl at: ", address(deployed));
        } else {
            console.log("Code found at expected address, skipping deployment");
        }
    }

    function _deploySemiModularAccountImpl(bytes32 salt, address expected) internal {
        console.log(string.concat("Deploying SemiModularAccountImpl with salt: ", vm.toString(salt)));

        address addr = Create2.computeAddress(
            salt,
            keccak256(abi.encodePacked(type(SemiModularAccount).creationCode, abi.encode(entryPoint))),
            CREATE2_FACTORY
        );
        if (expected != address(0) && addr != expected) {
            console.log("Expected address mismatch");
            console.log("Expected: ", expected);
            console.log("Actual: ", addr);
            success = false;
            return;
        }

        if (expected == address(0) || addr.code.length == 0) {
            console.log("No code found at expected address, deploying...");
            SemiModularAccount deployed = new SemiModularAccount{salt: salt}(entryPoint);

            if (expected != address(0) && address(deployed) != expected) {
                console.log("Deployed address mismatch");
                console.log("Expected: ", expected);
                console.log("Deployed: ", address(deployed));
                success = false;
                return;
            }

            SMA_IMPL = address(deployed);
            console.log("Deployed SemiModularAccount at: ", address(deployed));
        } else {
            console.log("Code found at expected address, skipping deployment");
        }
    }

    function _deploySingleSignerValidation(bytes32 salt, address expected) internal {
        console.log(string.concat("Deploying SingleSignerValidationModule with salt: ", vm.toString(salt)));

        address addr = Create2.computeAddress(
            salt, keccak256(abi.encodePacked(type(SingleSignerValidationModule).creationCode)), CREATE2_FACTORY
        );
        if (expected != address(0) && addr != expected) {
            console.log("Expected address mismatch");
            console.log("Expected: ", expected);
            console.log("Actual: ", addr);
            success = false;
            return;
        }

        if (expected == address(0) || addr.code.length == 0) {
            console.log("No code found at expected address, deploying...");
            SingleSignerValidationModule deployed = new SingleSignerValidationModule{salt: salt}();

            if (expected != address(0) && address(deployed) != expected) {
                console.log("Deployed address mismatch");
                console.log("Expected: ", expected);
                console.log("Deployed: ", address(deployed));
                success = false;
                return;
            }

            SINGLE_SIGNER_VALIDATION_MODULE = address(deployed);
            console.log("Deployed SingleSignerValidationModule at: ", address(deployed));
        } else {
            console.log("Code found at expected address, skipping deployment");
        }
    }

    function _deployAccountFactory(bytes32 salt, address expected) internal {
        console.log(string.concat("Deploying AccountFactory with salt: ", vm.toString(salt)));

        address addr = Create2.computeAddress(
            salt,
            keccak256(
                abi.encodePacked(
                    type(AccountFactory).creationCode,
                    abi.encode(
                        entryPoint, accountImpl, semiModularAccountImpl, singleSignerValidationModule, owner
                    )
                )
            ),
            CREATE2_FACTORY
        );
        if (expected != address(0) && addr != expected) {
            console.log("Expected address mismatch");
            console.log("Expected: ", expected);
            console.log("Actual: ", addr);
            success = false;
            return;
        }

        if (expected == address(0) || addr.code.length == 0) {
            console.log("No code found at expected address, deploying...");
            AccountFactory deployed = new AccountFactory{salt: salt}(
                entryPoint,
                ReferenceModularAccount(payable(accountImpl)),
                SemiModularAccount(payable(semiModularAccountImpl)),
                singleSignerValidationModule,
                owner
            );

            if (expected != address(0) && address(deployed) != expected) {
                console.log("Deployed address mismatch");
                console.log("Expected: ", expected);
                console.log("Deployed: ", address(deployed));
                success = false;
                return;
            }

            FACTORY = address(deployed);
            console.log("Deployed AccountFactory at: ", address(deployed));
        } else {
            console.log("Code found at expected address, skipping deployment");
        }
    }

    function _addStakeForFactory(uint32 unstakeDelay, uint256 stakeAmount) internal {
        console.log("Adding stake to factory");

        uint256 currentStake = entryPoint.getDepositInfo(FACTORY).stake;
        console.log("Current stake: ", currentStake);
        uint256 stakeToAdd = stakeAmount - currentStake;

        if (stakeToAdd > 0) {
            console.log("Adding stake: ", stakeToAdd);
            AccountFactory(FACTORY).addStake{value: stakeToAdd}(unstakeDelay);
            console.log("Staked factory: ", address(FACTORY));
            console.log("Total stake amount: ", entryPoint.getDepositInfo(address(FACTORY)).stake);
            console.log("Unstake delay: ", entryPoint.getDepositInfo(address(FACTORY)).unstakeDelaySec);
        } else {
            console.log("No stake to add");
        }
    }
}
