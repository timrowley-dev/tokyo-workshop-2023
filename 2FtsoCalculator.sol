// SPDX-License-Identifier: MIT

// Collects USD prices from FTSO to calculate price of an asset (ie, XRP) 
// and contains function to calculate how token for token exchnage rate

pragma solidity ^0.8.6;

import {IFtso} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtso.sol";
import {IPriceSubmitter} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IPriceSubmitter.sol";
import {IFtsoRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtsoRegistry.sol";


contract FtsoCalculator {
    constructor() {}

    function getPriceSubmitter() public view virtual returns (IPriceSubmitter) {
        return IPriceSubmitter(0x1000000000000000000000000000000000000003);
    }

    function getSupportedSymbols() public view returns (string[] memory) {
         IFtsoRegistry ftsoRegistry = IFtsoRegistry(
            address(getPriceSubmitter().getFtsoRegistry())
        );
        
        return ftsoRegistry.getSupportedSymbols();
    }

    function getSymbolUsdPrice(string memory symbol) public view returns (uint256 price) {
        // Instantiate deployed instance of ftsoRegistry to call its methods
        IFtsoRegistry ftsoRegistry = IFtsoRegistry(
            address(getPriceSubmitter().getFtsoRegistry())
        );

        (price, ) = ftsoRegistry.getCurrentPrice(symbol);
    }

    // Returns in 5 decimals
    function tokensToUsd(string memory symbol, uint256 amount) public view returns (uint256 usdValue) {
        uint256 price = getSymbolUsdPrice(symbol);
        usdValue = price * amount;
    }

    // WARN: Contains precision errors
    function tokensToTokens(string memory fromSymbol, string memory toSymbol, uint256 amount) public view returns (uint256) {
        uint256 fromSymbolPrice = getSymbolUsdPrice(fromSymbol);
        uint256 toSymbolPrice = getSymbolUsdPrice(toSymbol);
        uint256 fromSymbolUsdValue = fromSymbolPrice * amount;
        
        return (fromSymbolUsdValue / toSymbolPrice);
    }

}