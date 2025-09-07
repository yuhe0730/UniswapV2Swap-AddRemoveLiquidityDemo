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
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract UniswapV2SwapDemo {
    address private immutable router;

    event SwapExecuted(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    error DeadlineExceeded();
    error InvalidPathLength();

    constructor(address _router) {
        router = _router;
    }

    function _prepareToken(address tokenIn, uint256 amountIn) internal {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(router, amountIn);
    }

    function swapExactAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (uint256 actualAmountOut) {
        if (deadline < block.timestamp) {
            revert DeadlineExceeded();
        }
        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        _prepareToken(tokenIn, amountIn);

        uint256[] memory amounts = IUniswapV2Router(router)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                deadline
            );

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amounts[1]);
        return amounts[1];
    }

    function swapExactAmountInMultiHop(
        address[] calldata path,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (uint256 actualAmountOut) {
        if (deadline < block.timestamp) {
            revert DeadlineExceeded();
        }
        if (path.length < 2) {
            revert InvalidPathLength();
        }
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        _prepareToken(tokenIn, amountIn);

        uint256[] memory amounts = IUniswapV2Router(router)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                deadline
            );
        emit SwapExecuted(
            msg.sender,
            tokenIn,
            tokenOut,
            amountIn,
            amounts[amounts.length - 1]
        );
        return amounts[amounts.length - 1];
    }

    function swapExactAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountInMax,
        uint256 amountOut,
        uint256 deadline
    ) external returns (uint256 actualAmountIn) {
        if (deadline < block.timestamp) {
            revert DeadlineExceeded();
        }
        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        _prepareToken(tokenIn, amountInMax);

        uint256[] memory amounts = IUniswapV2Router(router)
            .swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                msg.sender,
                deadline
            );

        if (amounts[0] < amountInMax) {
            IERC20(tokenIn).transfer(msg.sender, amountInMax - amounts[0]);
        }

        IERC20(tokenIn).approve(router, 0);
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amounts[0], amountOut);
        return amounts[0];
    }

    function swapMultiHopExactAmountOut(
        address[] calldata path,
        uint256 amountInMax,
        uint256 amountOut,
        uint256 deadline
    ) external returns (uint256 actualAmountIn) {
        if (deadline < block.timestamp) {
            revert DeadlineExceeded();
        }
        if (path.length < 2) {
            revert InvalidPathLength();
        }
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        _prepareToken(tokenIn, amountInMax);

        uint256[] memory amounts = IUniswapV2Router(router)
            .swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                msg.sender,
                deadline
            );

        if (amounts[0] < amountInMax) {
            IERC20(tokenIn).transfer(msg.sender, amountInMax - amounts[0]);
        }

        IERC20(tokenIn).approve(address(router), 0);
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amounts[0], amountOut);
        return amounts[0];
    }

    function swapExactAmountInSupportingFeeOn(
        address[] calldata path,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        if (deadline < block.timestamp) {
            revert DeadlineExceeded();
        }
        if (path.length < 2) {
            revert InvalidPathLength();
        }
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];
        _prepareToken(tokenIn, amountIn);

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);

        IUniswapV2Router(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                deadline
            );

        uint256 balanceAfter = IERC20(tokenOut).balanceOf(msg.sender);
        amountOut = balanceAfter - balanceBefore;

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }
}
