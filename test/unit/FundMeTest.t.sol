// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant START_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, START_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // Disabled: test fails to assert something
    // function testFailsWithoutEnoughEth() public {
        // vm.expectRevert(); // assert next line tx fails
        // fundMe.fund(); // send 0
    // }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAmountFunded(USER);
        assertEq(SEND_VALUE, amountFunded);
    }

    function testFundAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assertEq(USER, fundMe.getFunder(0));
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawWithMultipleFunders() public {
        // arrange
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i < numberOfFunders; i++) {
            // vm.prank() new address
            // vm.deal() to new address
            hoax(address(i), START_BALANCE);
            // fund from new address
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        uint256 gasStart = gasleft();   //1000
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());   //c: 200
        fundMe.withdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = gasStart - gasEnd;
        console.log("gas used: ", gasUsed);
        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawCheaperWithMultipleFunders() public {
        // arrange
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i < numberOfFunders; i++) {
            // vm.prank() new address
            // vm.deal() to new address
            hoax(address(i), START_BALANCE);
            // fund from new address
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // act
        uint256 gasStart = gasleft();   //1000
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());   //c: 200
        fundMe.withdrawCheaper();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = gasStart - gasEnd;
        console.log("gas used: ", gasUsed);
        // assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
        assertEq(endingFundMeBalance, 0);
    }
}
