// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BridgeDeposit.sol";
import "../src/BridgeMint.sol";

contract AddSupportedToken is Script {
    function run() external {
        address contractAddress = vm.envAddress("BRIDGE_MINT");
        address tokenAddress = vm.envAddress("TOKEN_MINT");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        Bridge bridge = BridgeDeposit(contractAddress);

        vm.startBroadcast(deployerPrivateKey);

        bridge.addSupportedToken(tokenAddress);

        vm.stopBroadcast();
    }
}
