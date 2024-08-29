// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/BridgeDeposit.sol";

contract DepositTokens is Script {
    function run() external {
        address contractAddress = vm.envAddress("BRIDGE_DEPOSIT");
        address tokenAddress = vm.envAddress("TOKEN_DEPOSIT");
        Token token = Token(tokenAddress);
        Bridge bridge = BridgeDeposit(contractAddress);
        uint256 amount = 100 * 1e18;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        token.approve(contractAddress, amount);

        bridge.deposit(tokenAddress, amount);

        vm.stopBroadcast();
    }
}
