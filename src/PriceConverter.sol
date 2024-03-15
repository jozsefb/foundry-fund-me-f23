// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // address: 0x694AA1769357215DE4FAC081bf1f309aDC325306 --- sepolia eth/usd address
        // abi - imported
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) public view returns (uint256) {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = ethAmount * ethPrice / 1e18;
        return ethAmountInUsd;
    }
}
