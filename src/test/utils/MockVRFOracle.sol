// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "ds-test/test.sol";

import "../../VRFConsumer.sol";
import "../mocks/MockVRFCoordinator.sol";
import "./Hevm.sol";

contract MockVRFOracle {
    VRFConsumer internal vrfConsumer;
    MockVRFCoordinator internal mockVRFCoordinator;

    constructor(address _vrfConsumer, address _mockVRFCoordinator) public {
        vrfConsumer = VRFConsumer(_vrfConsumer);
        mockVRFCoordinator = MockVRFCoordinator(_mockVRFCoordinator);
    }

    function callBackWithRandomness(
        bytes32 requestId,
        uint256 randomness,
        address returnAddress
    ) public {
        mockVRFCoordinator.callBackWithRandomness(
            requestId,
            randomness,
            returnAddress
        );
    }
}
