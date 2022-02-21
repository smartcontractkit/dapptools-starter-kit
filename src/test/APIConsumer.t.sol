// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {stdError, stdCheats} from "forge-std/stdlib.sol";
import {Vm} from "forge-std/Vm.sol";
import {APIConsumer} from "../APIConsumer.sol";
import {LinkToken} from "./mocks/LinkToken.sol";
import {MockOracle} from "./mocks/MockOracle.sol";

contract APIConsumerTestBase is DSTest, stdCheats {
    Vm public constant vm = Vm(HEVM_ADDRESS);

    LinkToken linkToken;
    APIConsumer apiConsumer;
    MockOracle mockOracle;

    bytes32 public requestId;
    uint256 public callbackValue = 777;

    function setUp() public {
        linkToken = new LinkToken();
        mockOracle = new MockOracle(address(linkToken));
        apiConsumer = new APIConsumer(
            address(mockOracle),
            "d5270d1c311941d0b08bead21fea7747",
            10**17,
            address(linkToken)
        );
        requestId = keccak256(
            abi.encodePacked(address(apiConsumer), uint256(1))
        );
        linkToken.transfer(address(apiConsumer), 1000 ether);
    }
}

contract APIConsumerUnitTest is APIConsumerTestBase {
    event ChainlinkRequested(bytes32 indexed id);
    event ChainlinkFulfilled(bytes32 indexed id);

    /** Gas benchmarking
     *************************************************************************/

    function testGas_apiRequest() public {
        apiConsumer.requestVolumeData();
    }

    /** Correctness tests
     *************************************************************************/

    function test_apiRequest() public {
        vm.expectEmit(true, false, false, true);
        emit ChainlinkRequested(requestId);

        apiConsumer.requestVolumeData();
    }

    function test_apiRequestResponse() public {
        apiConsumer.requestVolumeData();
        mockOracle.fulfillOracleRequest(requestId, bytes32(callbackValue));
        assertEq(apiConsumer.volume(), callbackValue);
    }
}

contract APIConsumerIntegrationTest is APIConsumerTestBase {
    event DataFulfilled(uint256 volume);

    function test_apiRequestCallback() public {
        apiConsumer.requestVolumeData();

        vm.expectEmit(true, false, false, true);
        emit DataFulfilled(callbackValue);

        mockOracle.fulfillOracleRequest(requestId, bytes32(callbackValue));
        assertEq(apiConsumer.volume(), callbackValue);
    }
}
