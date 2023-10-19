// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MegaMask {

    //-----------------------------
    //DEFINE VARIABLES & CONSTANTS
    //-----------------------------
    uint256 constant PRICE_DECIMALS = 2;

    struct Product {
        string productPicCID; //the CID of the uploaded image content of the product using web3.storage
        string productName; //the product name
        uint256 price; //the product price
    }

    mapping (address => Product[]) public smartAccountToInventory; //gets the product inventory based on the detected smart account address

    //TODO: function to post product details to different chains at once
    //TODO: function to fetch product details from different chain at once, getProduct(address) -> Product[]
    //TODO: post attestation as merchant to attestation contract in Sepolia




}
