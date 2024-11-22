// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "@eth-infinitism/account-abstraction/core/EntryPoint.sol";
import {SingleOwnerPlugin} from "@erc6900/plugins/owner/SingleOwnerPlugin.sol";

contract DeploySingleOwnerPlugin is Script {
    SingleOwnerPlugin public plugin;

    function run() external returns (SingleOwnerPlugin) {
        vm.startBroadcast();
        plugin = new SingleOwnerPlugin();
        vm.stopBroadcast();

        return plugin;
    }
}
