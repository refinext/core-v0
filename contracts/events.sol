// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Events {
    event LiquidityAdded (
        address asset_,
        uint256 amount_,
        address from_
    );

    event LiquidityRemoved (
        address asset_,
        uint256 amount_,
        address from_
    );

    event xRefinance(
        address from_
    );
}