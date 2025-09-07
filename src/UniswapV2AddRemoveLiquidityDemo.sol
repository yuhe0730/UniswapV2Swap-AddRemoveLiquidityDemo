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

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract UniswapV2AddRemoveLiquidityDemo {
    address private immutable router;
    address private immutable factory;

    event LiquidityAdded(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 liquidity,
        uint256 amountA,
        uint256 amountB
    );

    error InsufficientLiquidity(uint256 requested, uint256 available);
    error PairNotExist(address tokenA, address tokenB);
    error DeadlineExceeded();

    constructor(address _router, address _factory) {
        router = _router;
        factory = _factory;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amountA,
        uint256 _amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (deadline < block.timestamp) {
            revert DeadlineExceeded();
        }

        IERC20(tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), _amountB);
        IERC20(tokenA).approve(router, _amountA);
        IERC20(tokenB).approve(router, _amountB);

        (amountA, amountB, liquidity) = IUniswapV2Router(router).addLiquidity(
            tokenA,
            tokenB,
            _amountA,
            _amountB,
            amountAMin,
            amountBMin,
            msg.sender,
            deadline
        );

        if (_amountA > amountA) {
            IERC20(tokenA).transfer(msg.sender, _amountA - amountA);
        }
        if (_amountB > amountB) {
            IERC20(tokenB).transfer(msg.sender, _amountB - amountB);
        }

        emit LiquidityAdded(
            msg.sender,
            tokenA,
            tokenB,
            amountA,
            amountB,
            liquidity
        );
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 liquidity,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        if (deadline < block.timestamp) {
            revert DeadlineExceeded();
        }

        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            revert PairNotExist(tokenA, tokenB);
        }

        uint256 userLiquidity = IERC20(pair).balanceOf(msg.sender);
        if (liquidity > userLiquidity) {
            revert InsufficientLiquidity(liquidity, userLiquidity);
        }

        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(router, liquidity);

        (amountA, amountB) = IUniswapV2Router(router).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            msg.sender,
            deadline
        );

        emit LiquidityRemoved(
            msg.sender,
            tokenA,
            tokenB,
            liquidity,
            amountA,
            amountB
        );
    }
}
