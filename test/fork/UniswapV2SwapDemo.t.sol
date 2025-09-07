// SPDX-License-Identifier: MIT
// Contract elements should be laid out in the following order:
// Pragma statements
// Import statements
// Events
// Errors
// Interfaces
// Libraries
// Contracts
// Inside each contract, library or interface, use the following order:
// Type declarations
// State variables
// Events
// Errors
// Modifiers
// Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IUniswapV2Router, IERC20, UniswapV2SwapDemo} from "src/UniswapV2SwapDemo.sol";

contract UniswapV2SwapDemoTest is Test {
    UniswapV2SwapDemo public swapper;
    address public immutable router = vm.envAddress("ROUTER");
    address public immutable tokenA = vm.envAddress("TOKENA");
    address public immutable tokenB = vm.envAddress("TOKENB");
    address public immutable tokenC = vm.envAddress("TOKENC");
    address public immutable user = vm.envAddress("USER");
    uint256 public immutable unix_time = vm.envUint("UNIX_TIME");

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        swapper = new UniswapV2SwapDemo(router);
        vm.warp(unix_time);
        vm.startPrank(user);
    }

    function testSwapExactAmountIn() public {
        uint256 amountIn = 10 ether;

        IERC20(tokenA).approve(address(swapper), amountIn);

        uint256 balInBefore = IERC20(tokenA).balanceOf(user);
        uint256 balOutBefore = IERC20(tokenB).balanceOf(user);

        uint256 actualAmountOut = swapper.swapExactAmountIn(
            tokenA,
            tokenB,
            amountIn,
            1,
            unix_time + 1
        );

        uint256 balInAfter = IERC20(tokenA).balanceOf(user);
        uint256 balOutAfter = IERC20(tokenB).balanceOf(user);

        assertEq(amountIn, balInBefore - balInAfter);
        assertEq(actualAmountOut, balOutAfter - balOutBefore);
    }

    function testSwapExactAmountInMultiHop() public {
        uint256 amountIn = 10 ether;

        IERC20(tokenA).approve(address(swapper), amountIn);

        address[] memory path = new address[](3);
        path[0] = tokenA;
        path[1] = tokenB;
        path[2] = tokenC;

        uint256 balInBefore = IERC20(tokenA).balanceOf(user);
        uint256 balOutBefore = IERC20(tokenC).balanceOf(user);

        uint256 actualAmountOut = swapper.swapExactAmountInMultiHop(
            path,
            amountIn,
            1,
            unix_time + 1
        );

        uint256 balInAfter = IERC20(tokenA).balanceOf(user);
        uint256 balOutAfter = IERC20(tokenC).balanceOf(user);

        assertEq(amountIn, balInBefore - balInAfter);
        assertEq(actualAmountOut, balOutAfter - balOutBefore);
    }

    function testSwapExactAmountOut() public {
        uint256 amountOut = 10 ether;
        uint256 amountInMax = 50 ether;

        IERC20(tokenA).approve(address(swapper), amountInMax);

        uint256 balInBefore = IERC20(tokenA).balanceOf(user);
        uint256 balOutBefore = IERC20(tokenB).balanceOf(user);

        uint256 actualAmountIn = swapper.swapExactAmountOut(
            tokenA,
            tokenB,
            amountInMax,
            amountOut,
            unix_time + 1
        );

        uint256 balInAfter = IERC20(tokenA).balanceOf(user);
        uint256 balOutAfter = IERC20(tokenB).balanceOf(user);

        assertEq(amountOut, balOutAfter - balOutBefore);
        assertEq(actualAmountIn, balInBefore - balInAfter);
    }

    function testSwapMultiHopExactAmountOut() public {
        uint256 amountOut = 10 ether;
        uint256 amountInMax = 50 ether;

        IERC20(tokenA).approve(address(swapper), amountInMax);

        address[] memory path = new address[](3);
        path[0] = tokenA;
        path[1] = tokenB;
        path[2] = tokenC;

        uint256 balInBefore = IERC20(tokenA).balanceOf(user);
        uint256 balOutBefore = IERC20(tokenC).balanceOf(user);

        uint256 actualAmountIn = swapper.swapMultiHopExactAmountOut(
            path,
            amountInMax,
            amountOut,
            unix_time + 1
        );

        uint256 balInAfter = IERC20(tokenA).balanceOf(user);
        uint256 balOutAfter = IERC20(tokenC).balanceOf(user);

        assertEq(amountOut, balOutAfter - balOutBefore);
        assertEq(actualAmountIn, balInBefore - balInAfter);
    }
}
