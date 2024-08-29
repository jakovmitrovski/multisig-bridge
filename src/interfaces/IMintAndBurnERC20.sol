// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IMintAndBurnERC20 is IAccessControl, IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address owner, uint256 amount) external;
}
