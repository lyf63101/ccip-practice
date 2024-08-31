// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

import {CrossChainNameServiceLookup} from "../src/CrossChainNameServiceLookup.sol";
import {CrossChainNameServiceReceiver} from "../src/CrossChainNameServiceReceiver.sol";
import {CrossChainNameServiceRegister} from "../src/CrossChainNameServiceRegister.sol";

contract CCNSTest is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint256 ethSepoliaFork;
    uint256 arbSepoliaFork;
    Register.NetworkDetails ethSepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;

    address alice;
    CrossChainNameServiceLookup public ethSepoliaCCNSLookup;
    CrossChainNameServiceLookup public arbSepoliaCCNSLookup;
    CrossChainNameServiceReceiver public ethSepoliaCCNSReceiver;
    CrossChainNameServiceRegister public arbSepoliaCCNSRegister;

    function setUp() public {
        alice = makeAddr("alice");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString(
            "ETHEREUM_SEPOLIA_RPC_URL"
        );
        string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString(
            "ARBITRUM_SEPOLIA_RPC_URL"
        );
        ethSepoliaFork = vm.createFork(ETHEREUM_SEPOLIA_RPC_URL);
        arbSepoliaFork = vm.createSelectFork(ARBITRUM_SEPOLIA_RPC_URL);

        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        );
        vm.selectFork(ethSepoliaFork);

        // step 1, deploy lookup and receiver in ehtereum sepolia
        assertEq(vm.activeFork(), ethSepoliaFork);

        ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(
            block.chainid
        ); // 目前我们处于Ethereum Sepolia的分叉网络中
        assertEq(
            ethSepoliaNetworkDetails.chainSelector,
            16015286601757825753,
            "Sanity check: Ethereum Sepolia chain selector should be 16015286601757825753"
        );

        ethSepoliaCCNSLookup = new CrossChainNameServiceLookup();
        ethSepoliaCCNSReceiver = new CrossChainNameServiceReceiver(
            ethSepoliaNetworkDetails.routerAddress,
            address(ethSepoliaCCNSLookup),
            arbSepoliaNetworkDetails.chainSelector
        );
        ethSepoliaCCNSLookup.setCrossChainNameServiceAddress(
            address(ethSepoliaCCNSReceiver)
        );

        // step 2, deploy lookup and register in arbitum sepolia
        vm.selectFork(arbSepoliaFork);
        assertEq(vm.activeFork(), arbSepoliaFork);
        // 目前我们处于Arbitrum Sepolia的分叉网络中
        assertEq(
            arbSepoliaNetworkDetails.chainSelector,
            3478487238524512106,
            "Sanity check: Arbitrum Sepolia chain selector should be 3478487238524512106"
        );

        arbSepoliaCCNSLookup = new CrossChainNameServiceLookup();
        arbSepoliaCCNSRegister = new CrossChainNameServiceRegister(
            arbSepoliaNetworkDetails.routerAddress,
            address(arbSepoliaCCNSLookup)
        );
        arbSepoliaCCNSLookup.setCrossChainNameServiceAddress(
            address(arbSepoliaCCNSRegister)
        );
    }

    function test_arbSepoliaRegister() public {
        vm.startPrank(alice);
        arbSepoliaCCNSRegister.register("alice.ccns");

        assertEq(arbSepoliaCCNSLookup.lookup("alice.ccns"), address(alice));

        vm.selectFork(ethSepoliaFork);
        assertEq(ethSepoliaCCNSLookup.lookup("alice.ccns"), address(0));
        vm.stopPrank();
    }

    function test_crossChainRegister() public {
        address(arbSepoliaCCNSRegister).call{value: 1 ether}("");
        arbSepoliaCCNSRegister.enableChain(
            ethSepoliaNetworkDetails.chainSelector,
            address(ethSepoliaCCNSReceiver),
            2000000
        );

        assertEq(address(arbSepoliaCCNSRegister).balance, 10 ** 18);

        vm.startPrank(alice);
        arbSepoliaCCNSRegister.register("alice.ccns");
        vm.stopPrank();
        assertEq(arbSepoliaCCNSLookup.lookup("alice.ccns"), address(alice));

        ccipLocalSimulatorFork.switchChainAndRouteMessage(ethSepoliaFork); // 这行代码将更换CHAINLINK CCIP DONs, 不要遗漏
        assertEq(vm.activeFork(), ethSepoliaFork);
        assertEq(ethSepoliaCCNSLookup.lookup("alice.ccns"), address(alice));
    }
}
