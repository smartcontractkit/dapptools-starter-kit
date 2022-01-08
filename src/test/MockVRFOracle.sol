// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../VRFConsumer.sol";
import "./mocks/MockVRFCoordinator.sol";
import "./mocks/LinkToken.sol";
import "ds-test/test.sol";
import "./utils/MockVRFOracle.sol";

contract VRFConsumerTest is DSTest {
    MockVRFCoordinator public vrfCoordinatorMock;
    LinkToken public linkToken;
    VRFConsumer public vrfConsumer;
    MockVRFOracle public mockVRFOracle;
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public constant RANDOM_RESULT = 777;

    function setUp() public {
        linkToken = new LinkToken();
        vrfCoordinatorMock = new MockVRFCoordinator(address(linkToken));
        vrfConsumer = new VRFConsumer(
            keyHash,
            address(vrfCoordinatorMock),
            address(linkToken),
            fee
        );
        mockVRFOracle = new MockVRFOracle(
            address(vrfConsumer),
            address(vrfCoordinatorMock)
        );
    }

    function test_consumer_can_request_randomness() public {
        linkToken.transfer(address(vrfConsumer), 100);
        vrfConsumer.getRandomNumber();
    }

    function test_consumer_can_receive_random_number() public {
        linkToken.transfer(address(vrfConsumer), 100);
        bytes32 requestId = vrfConsumer.getRandomNumber();
        mockVRFOracle.callBackWithRandomness(
            requestId,
            RANDOM_RESULT,
            address(vrfConsumer)
        );
        assertTrue(vrfConsumer.randomResult() == RANDOM_RESULT);
    }
}
