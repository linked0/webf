// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEntryPoint} from "@eth-infinitism/account-abstraction/interfaces/IEntryPoint.sol";
import {Script, console} from "forge-std/Script.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {Counter} from "../test/mocks/Counter.sol";

contract DeployCounterScript is Script {
    address public owner = vm.envAddress("OWNER");

    function run() public {
        console.log("******** Deploying Counter ********");
        console.log("Chain: ", block.chainid);
        console.log("Factory owner: ", owner);

        vm.startBroadcast();
        Counter counter = new Counter();
        vm.stopBroadcast();
        console.log("Deployed Counter at: ", address(counter));
    }
}

