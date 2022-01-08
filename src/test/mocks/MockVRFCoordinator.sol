// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorMock.sol";

contract MockVRFCoordinator is VRFCoordinatorMock {
    constructor(address linkToken) VRFCoordinatorMock(linkToken) {}
}
