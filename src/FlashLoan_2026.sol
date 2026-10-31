// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Import Aave V3 flash loan base contract and addresses provider interface
import {FlashLoanSimpleReceiverBase} from "https://raw.githubusercontent.com/aave/aave-v3-core/master/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "https://raw.githubusercontent.com/aave/aave-v3-core/master/contracts/interfaces/IPoolAddressesProvider.sol";

// Minimal ERC-20 token interface for balance checks and spending approvals
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// This is the `PoolAddressProvider` contract on the Aave V3 Sepolia Testnet - 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A
// to use for deploying this contract to Sepolia. For other networks, see this link - https://aave.com/docs/reference/addresses

contract Flashloan is FlashLoanSimpleReceiverBase {
    address public owner;

    // Restricts function access exclusively to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Sets the deployment transaction sender as the contract owner
    constructor(
        IPoolAddressesProvider provider
    ) FlashLoanSimpleReceiverBase(provider) {
        owner = msg.sender;
    }

    // Mandatory Aave callback executed immediately after funds are disbursed
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Ensure the callback originates directly from the official Aave Pool
        require(msg.sender == address(POOL), "Unauthorized caller");

        // Verify that this contract initiated the flash loan request
        require(initiator == address(this), "Invalid initiator");

        // Confirm the flash-loaned funds have successfully arrived in the contract
        require(
            IERC20(asset).balanceOf(address(this)) >= amount,
            "Insufficient loan balance"
        );

        // --- Insert custom flash loan logic (e.g., arbitrage, liquidations) here ---

        // Calculate total repayment amount (borrowed principal + Aave protocol fee)
        uint totalDebt = amount + premium;

        // Reset allowance to zero (required for tokens like USDT before updating)
        require(
            IERC20(asset).approve(address(POOL), 0),
            "Allowance reset failed"
        );

        // Approve the Aave Pool to pull the total repayment amount from this contract
        require(
            IERC20(asset).approve(address(POOL), totalDebt),
            "Approval failed"
        );

        return true;
    }

    // Initiates a single-asset flash loan from the Aave lending pool
    function flashloan(address asset, uint256 amount) external onlyOwner {
        bytes memory params = "";

        // Trigger Aave's flashLoanSimple flow
        POOL.flashLoanSimple(address(this), asset, amount, params, 0);
    }
}
