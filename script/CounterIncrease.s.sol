// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/Counter.sol";
import {Script, console} from "forge-std/Script.sol";

contract CallIncrease is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address myContractAddress = vm.envAddress("COUNTER_CONTRACT");

        console.log(deployerPrivateKey, myContractAddress);
        // Load the contract
        Counter myContract = Counter(myContractAddress);

        // Start broadcasting the transaction
        vm.startBroadcast(deployerPrivateKey);

        // Call the `increase` function
        myContract.increment();

        console.log("Successfully called `increment` on:", myContractAddress);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}