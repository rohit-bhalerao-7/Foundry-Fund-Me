// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //0.1 ether = 100000000000000000 wei
    uint256 constant STARTING_BALANCE = 10 ether;
   // uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 50 * 1e18);
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughETH() public {
        vm.expectRevert(); //We expect that next line should fail and revert us
        //assert(This transcn fails/reverts)
        fundMe.fund(); //send 0 funds/ETH which contradicts the require statement of MIN_USD
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //This says that next transaction will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        // modifier is a function which is called before the test
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    } //instead of funding test every time we can use modifier to fund and then test

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // We expect that next line should fail and revert us
        vm.prank(USER); //This says that next transaction will be sent by USER
        fundMe.withdraw(); // This should fail as USER is not owner
    } // expectRevert won't work on vm.call as it is not a transaction

    function testWithdrawWithSingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; // address(fundMe) is address of contract

        //Act
        //uint256 gasStart = gasleft();// 1000 GAS // gasleft() is a function which returns the gas left

        //vm.txGasPrice(GAS_PRICE); //sets the gas price for next transaction
        vm.prank(fundMe.getOwner()); //Cost 100 GAS
        fundMe.withdraw(); //should have spent gas here?? but it didn't
        
        //uint256 gasEnd = gasleft(); // 900 GAS
        //uint256 gasUsed = (gasStart - gasEnd)*tx.gasprice; // 100 GAS
        //console.log(gasUsed);
        //Since we are working with anvil chain gas prices are default to zero
        //To simulate real gas prices we will use tx.gasprice
        

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); // as we have withdrawn all the funds
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        ); // as owner has withdrawn all the funds
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; //can't typecast address to uint256 so we use uint160
        uint160 startingFunderIndex = 1; // start with 1 as 0 is owner
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // hoaxes the address with SEND_VALUE, instead of prank and deal we use hoax
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; // address(fundMe) is address of contract

        //Act
        //anything between startPrank and stopPrank will be sent by owner
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0); // as we have withdrawn all the funds))
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        ); // as owner has withdrawn all the funds
    }

        function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10; //can't typecast address to uint256 so we use uint160
        uint160 startingFunderIndex = 1; // start with 1 as 0 is owner
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // hoaxes the address with SEND_VALUE, instead of prank and deal we use hoax
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance; // address(fundMe) is address of contract

        //Act
        //anything between startPrank and stopPrank will be sent by owner
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0); // as we have withdrawn all the funds))
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        ); // as owner has withdrawn all the funds
    }
    
}
