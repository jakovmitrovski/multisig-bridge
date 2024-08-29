// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Token.sol";

contract BurnTokens is Script {
    function run() external {
        address tokenAddress = vm.envAddress("TOKEN_DEPOSIT");
        address burnFrom = makeAddr("BURN_FROM");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 amount = 1000 * 1e18;

        Token token = Token(tokenAddress);

        vm.startBroadcast(deployerPrivateKey);

        token.burn(burnFrom, amount);

        vm.stopBroadcast();
    }
}
