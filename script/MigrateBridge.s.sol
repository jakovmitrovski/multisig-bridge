// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Bridge.sol";
import "../src/BridgeDeposit.sol";

contract MigrateBridge is Script {
    function run() external {
        address contractAddress = vm.envAddress("BRIDGE_DEPOSIT");
        address migrateTo = vm.envAddress("MIGRATE_TO");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        Bridge bridge = BridgeDeposit(contractAddress);

        vm.startBroadcast(deployerPrivateKey);

        bridge.migrate(migrateTo);

        vm.stopBroadcast();
    }
}
