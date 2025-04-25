// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    struct Data {
        uint256 x;
        uint256 y;
    }
    /// Two independent storage slots
    Data public slotA;
    Data public slotB;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);

        slotB = slotA;
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
