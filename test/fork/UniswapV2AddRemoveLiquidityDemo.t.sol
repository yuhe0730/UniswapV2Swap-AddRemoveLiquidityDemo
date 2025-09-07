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
import {IUniswapV2Router, IERC20, IUniswapV2Factory, UniswapV2AddRemoveLiquidityDemo} from "src/UniswapV2AddRemoveLiquidityDemo.sol";

contract UniswapV2AddRemoveLiquidityDemoTest is Test {
    address public immutable router = vm.envAddress("ROUTER");
    address public immutable factory = vm.envAddress("FACTORY");
    address public immutable tokenA = vm.envAddress("TOKENA");
    address public immutable tokenB = vm.envAddress("TOKENB");
    address public immutable user = vm.envAddress("USER");
    uint256 public immutable unix_time = vm.envUint("UNIX_TIME");
    UniswapV2AddRemoveLiquidityDemo public liquidityProvider;
    address public pair;

    error InsufficientLiquidity(uint256 requested, uint256 available);
    error PairNotExist(address tokenA, address tokenB);
    error DeadlineExceeded();

    function setUp() public {
        string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        liquidityProvider = new UniswapV2AddRemoveLiquidityDemo(
            router,
            factory
        );
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }

        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        vm.warp(unix_time);
        vm.startPrank(user);
    }

    function testAddLiquidity() public {
        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        IERC20(tokenA).approve(address(liquidityProvider), amountA);
        IERC20(tokenB).approve(address(liquidityProvider), amountB);

        uint256 lpBalanceBefore = IERC20(pair).balanceOf(user);
        uint256 tokenABalanceBefore = IERC20(tokenA).balanceOf(user);
        uint256 tokenBBalanceBefore = IERC20(tokenB).balanceOf(user);

        (
            uint256 amountAUsed,
            uint256 amountBUsed,
            uint256 liquidity
        ) = liquidityProvider.addLiquidity(
                tokenA,
                tokenB,
                amountA,
                amountB,
                1,
                1,
                unix_time + 1
            );

        uint256 lpBalanceAfter = IERC20(pair).balanceOf(user);
        uint256 tokenABalanceAfter = IERC20(tokenA).balanceOf(user);
        uint256 tokenBBalanceAfter = IERC20(tokenB).balanceOf(user);

        assertEq(amountAUsed, tokenABalanceBefore - tokenABalanceAfter);
        assertEq(amountBUsed, tokenBBalanceBefore - tokenBBalanceAfter);
        assertEq(liquidity, lpBalanceAfter - lpBalanceBefore);
        assertGt(lpBalanceAfter, lpBalanceBefore);
        assertLt(tokenABalanceAfter, tokenABalanceBefore);
        assertLt(tokenBBalanceAfter, tokenBBalanceBefore);
    }

    function testRemoveLiquidity() public {
        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        IERC20(tokenA).approve(address(liquidityProvider), amountA);
        IERC20(tokenB).approve(address(liquidityProvider), amountB);

        liquidityProvider.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            1,
            1,
            unix_time + 1
        );

        uint256 lpBalanceBefore = IERC20(pair).balanceOf(user);
        uint256 tokenABalanceBefore = IERC20(tokenA).balanceOf(user);
        uint256 tokenBBalanceBefore = IERC20(tokenB).balanceOf(user);

        IERC20(pair).approve(address(liquidityProvider), lpBalanceBefore);
        (uint256 amountAGetted, uint256 amountBGetted) = liquidityProvider
            .removeLiquidity(
                tokenA,
                tokenB,
                1,
                1,
                lpBalanceBefore,
                unix_time + 1
            );

        uint256 lpBalanceAfter = IERC20(pair).balanceOf(user);
        uint256 tokenABalanceAfter = IERC20(tokenA).balanceOf(user);
        uint256 tokenBBalanceAfter = IERC20(tokenB).balanceOf(user);

        assertEq(lpBalanceAfter, 0);
        assertEq(amountAGetted, tokenABalanceAfter - tokenABalanceBefore);
        assertEq(amountBGetted, tokenBBalanceAfter - tokenBBalanceBefore);
        assertLt(lpBalanceAfter, lpBalanceBefore);
        assertGt(tokenABalanceAfter, tokenABalanceBefore);
        assertGt(tokenBBalanceAfter, tokenBBalanceBefore);
    }

    function testInsufficientLiquidity() public {
        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        IERC20(tokenA).approve(address(liquidityProvider), amountA);
        IERC20(tokenB).approve(address(liquidityProvider), amountB);

        liquidityProvider.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            1,
            1,
            unix_time + 1
        );

        uint256 lpBalance = IERC20(pair).balanceOf(user);
        IERC20(pair).approve(address(liquidityProvider), lpBalance + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                InsufficientLiquidity.selector,
                lpBalance + 1,
                lpBalance
            )
        );
        liquidityProvider.removeLiquidity(
            tokenA,
            tokenB,
            1,
            1,
            lpBalance + 1,
            unix_time + 1
        );
    }

    function testDeadlineExceeded() public {
        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;

        IERC20(tokenA).approve(address(liquidityProvider), amountA);
        IERC20(tokenB).approve(address(liquidityProvider), amountB);

        vm.expectRevert(DeadlineExceeded.selector);
        liquidityProvider.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            1,
            1,
            unix_time - 1
        );
    }
}
