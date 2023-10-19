// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MegaMask {

    //-----------------------------
    //DEFINE VARIABLES & CONSTANTS
    //-----------------------------
    struct Product {
        string productPicCID; //the CID of the uploaded image content of the product using web3.storage
        string productName; //the product name
        string price; //the product price
    }

    mapping (address => Product[]) public smartAccountToInventory; //gets the product inventory based on the detected smart account address

    //TODO: function to post product details to different chains at once (hyperlane)
    //TODO: function to fetch product details from different chain at once, getProduct(address) -> Product[] (hyperlane)
    //TODO: post attestation as merchant to attestation contract in Sepolia (wormhole)
    //TODO: resolver contract to check that a merchant attestaion exists in Sepolia
    //TODO: function to make an attestation that bill paid (wormhole)
    //TODO: function to fetch attestation from sepolia (hyperlane)




}
