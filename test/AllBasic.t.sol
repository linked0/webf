// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";

contract AllBasic {
    struct Data {
        uint val;
        uint[] arr;
        uint[2] staticArr;  // fixed-size static array
    }

    Data private d1;
    Data private d2;

    constructor() {
        reset();
    }

    /// Resets d1 and d2 to initial state
    function reset() public {
        // initialize d1
        d1.val = 1;
        d1.arr = new uint[](2);
        d1.arr[0] = 10;
        d1.arr[1] = 20;
        d1.staticArr[0] = 100;
        d1.staticArr[1] = 200;
        // clear d2
        delete d2;
    }

    /// 1) STORAGE → STORAGE: shallow alias
    function aliasStorage() external {
        Data storage s1 = d1;
        Data storage s2 = s1;
        s2.val = 99;
    }

    /// 2) STORAGE → MEMORY: deep copy
    function snapshot() external view returns (Data memory) {
        Data memory m = d1;
        m.val    = 55;  // does NOT affect d1
        m.arr[0] = 66;
        return m;
    }

    /// 3) MEMORY → STORAGE: deep copy
    function overwrite() external {
        Data memory m = d1;    // snapshot of d1
        m.val    = 77;
        m.arr[1] = 88;
        d2 = m;                // deep-copies all fields into d2
    }

    /// 4) MEMORY → MEMORY: shallow alias
    function memoryAlias() external pure returns (uint) {
        uint[] memory a = new uint[](2);
        a[0] = 1;
        a[1] = 2;
        uint[] memory b = a;   // b and a share the same buffer
        b[0] = 999;
        return a[0];           // returns 999
    }

    /// 5) MEMORY → MEMORY: manual deep copy
    function memoryDeepCopy(uint[] memory input) external pure returns (uint[] memory) {
        uint[] memory copy_ = new uint[](input.length);
        for (uint i = 0; i < input.length; ++i) {
            copy_[i] = input[i];
        }
        return copy_;
    }

    /// Explicit getters returning the full struct
    function getD1() external view returns (Data memory) {
        return d1;
    }

    function getD2() external view returns (Data memory) {
        return d2;
    }
}

contract AllBasicTest is Test {
    AllBasic basic;

    function setUp() public {
        basic = new AllBasic();
    }

    function testAliasStorage() public {
        basic.reset();
        AllBasic.Data memory d = basic.getD1();
        console.log("Initial d1.val:", d.val);
        assertEq(d.val, 1);

        basic.aliasStorage();

        d = basic.getD1();
        console.log("After aliasStorage, d1.val:", d.val);
        assertEq(d.val, 99);
    }

    function testSnapshotDoesNotMutateStorage() public {
        basic.reset();
        AllBasic.Data memory snap = basic.snapshot();
        // no logging here
        assertEq(snap.val, 55);
        assertEq(snap.arr[0], 66);
        assertEq(snap.arr[1], 20);
        assertEq(snap.staticArr[0], 100);
        assertEq(snap.staticArr[1], 200);
    }

    function testOverwriteCopiesToD2() public {
        basic.reset();
        AllBasic.Data memory beforeData = basic.getD2();
        console.log("Before overwrite, d2.val:", beforeData.val);
        assertEq(beforeData.val, 0);

        basic.overwrite();

        AllBasic.Data memory afterData = basic.getD2();
        console.log("After overwrite, d2.val:", afterData.val, "arr[1]:", afterData.arr[1]);
        assertEq(afterData.val, 77);
        assertEq(afterData.arr.length, 2);
        assertEq(afterData.arr[0], 10);
        assertEq(afterData.arr[1], 88);
        assertEq(afterData.staticArr[0], 100);
        assertEq(afterData.staticArr[1], 200);
    }

    function testMemoryAlias() public {
        basic.reset();
        // no logging here
        uint result = basic.memoryAlias();
        assertEq(result, 999);
    }

    function testMemoryDeepCopy() public {
        basic.reset();
        // no logging here
        uint[] memory input = new uint[](3);
        input[0] = 5;
        input[1] = 6;
        input[2] = 7;

        uint[] memory copy = basic.memoryDeepCopy(input);
        assertEq(copy.length, input.length);
        for (uint i = 0; i < input.length; ++i) {
            assertEq(copy[i], input[i]);
        }
    }
}
