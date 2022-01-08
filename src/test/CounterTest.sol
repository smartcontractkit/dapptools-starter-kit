// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Counter.sol";
import "ds-test/test.sol";
import "./utils/Hevm.sol";

contract CounterTest is DSTest {
    Counter public counter;
    uint256 public staticTime;
    uint256 public INTERVAL;
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    function setUp() public {
        staticTime = block.timestamp;
        counter = new Counter(INTERVAL);
        hevm.warp(staticTime);
    }

    function test_checkup_returns_false_before_time() public {
        (bool upkeepNeeded, ) = counter.checkUpkeep("0x");
        assertTrue(!upkeepNeeded);
    }

    function test_checkup_returns_true_after_time() public {
        hevm.warp(staticTime + INTERVAL + 1); // Needs to be more than the interval
        (bool upkeepNeeded, ) = counter.checkUpkeep("0x");
        assertTrue(upkeepNeeded);
    }

    function test_performUpkeep_updates_time() public {
        // Arrange
        uint256 currentCounter = counter.counter();

        // Act
        counter.performUpkeep("0x");

        // Assert
        assertTrue(counter.lastTimeStamp() == block.timestamp);
        assertTrue(currentCounter + 1 == counter.counter());
    }
}
