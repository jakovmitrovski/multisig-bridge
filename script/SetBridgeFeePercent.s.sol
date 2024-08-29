// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BridgeDeposit.sol";
import "../src/BridgeMint.sol";

contract SetBridgeFeePercent is Script {
    function run() external {
        address contractAddress = vm.envAddress("BRIDGE_DEPOSIT");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        uint8 newBridgeFeePercent = 2;

        Bridge bridge = BridgeDeposit(contractAddress);
        vm.startBroadcast(deployerPrivateKey);

        bridge.setBridgeFeePercent(newBridgeFeePercent);

        vm.stopBroadcast();
    }
}
