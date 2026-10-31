// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

// Import Aave flashloan code. By importing, you are saving resources from having to write out this code.
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/FlashLoanReceiverBase.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPoolAddressesProvider.sol";
import "https://github.com/aave/flashloan-box/blob/Remix/contracts/aave/ILendingPool.sol";

contract Flashloan is FlashLoanReceiverBase {
    /**
    The following constructor method is run when you create this flashloan smart contract. Make sure
    to specify the address of the Aave LendingPoolAddressProvider contract.This argument is different
    based on the environment you are working in. Visit the Aave docs to get this address.
    */

    constructor(
        address _addressProvider
    ) FlashLoanReceiverBase(_addressProvider) {}

    /**
    The following function is called by Aave to the flashloan contract after the contract has 
    received the flash-loaned amount
    */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        require(
            _amount <= getBalanceInternal(address(this), _reserve),
            "Invalid alance, was the flashloan successful?"
        );

        // Your logic goes here.
        // !! Ensure that *this contract* has enough `_reserve` funds to
        // pay back the `_fee` !!

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
    Call the following function when you want to execute a flash loan. The parameter 
    `_asset` is the address of the token you want to borrow in the flash loan. In our 
    example, the token we will borrow is DAI 
    */
    function flashloan(address _asset) public onlyOwner {
        bytes memory data = "";
        uint amount = 1 ether;

        ILendingPool lendingPool = ILendingPool(
            addressProvider.getLendingPool()
        );
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }
}
