// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BridgeDeposit.sol";

contract CollectValidatorFees is Script {
    function run() external {
        address contractAddress = vm.envAddress("BRIDGE_DEPOSIT");
        address tokenAddress = vm.envAddress("TOKEN_DEPOSIT");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        Bridge bridge = BridgeDeposit(contractAddress);

        vm.startBroadcast(deployerPrivateKey);

        for (uint8 i = 0; i < 3; i++) {
            bridge.collectValidatorFees(tokenAddress);
            vm.stopBroadcast();
        }
    }
}
