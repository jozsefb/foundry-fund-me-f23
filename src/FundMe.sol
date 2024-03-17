// Receive funds from anyone
// Be able to withdraw funds
// Set minimum amount in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint public constant MINIMUM_USD = 5e18;
    address[] private s_funders;
    mapping(address funders => uint256 fundedAmount) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    address private immutable i_owner;

    // 668214, 574030
    // 647841, 553725
    // 624682, 531222
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // allow users to send $
        // have minimum $ spent
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Didn't send enough ETH."); // 1e18 == 1 ETH == 1 * 10 ** 18 ---- (** == ^)
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;
    }

    function withdrawOptions() internal {
        for(uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // withdraw the funds
        // 1. transfer
        // 2. send
        // 3. call

        // 1: transfer
        // msg.sender - address
        // payable(msg.sender) - payable address
        payable(msg.sender).transfer(address(this).balance); // 2300 gas - throws an error if it costs more

        // 2: send
        bool sendSuccess = payable(msg.sender).send(address(this).balance); // 2300 gas - returns bool
        require(sendSuccess, "Send failed.");

        // 3: call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}(""); // forward all gas or set gas
        require(callSuccess, "Call failed.");
    }

    function withdraw() public onlyOwner {
        // reset funders
        for(uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // withdraw all funds
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed.");
    }

    function withdrawCheaper() public onlyOwner {
        // reset funders
        uint256 numberOfFunders = s_funders.length;
        for(uint256 i = 0; i < numberOfFunders; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // withdraw all funds
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed.");
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner, "Must be owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }

        _; // the rest of the code of the function
        // anything else to be done
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    
    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getAmountFunded(address funder) external view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
}
