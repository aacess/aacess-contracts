// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title MegaMask
 * @dev A smart contract for managing product inventory and attestation on different chains.
 */
contract MegaMask {
    //-----------------------------
    //DEFINE VARIABLES & CONSTANTS
    //-----------------------------

    /**
     * @dev Struct to store product details.
     * @param productPicCID The CID of the uploaded image content of the product using web3.storage.
     * @param productName The name of the product.
     * @param price The price of the product.
     */
    struct Product {
        string productPicCID;
        string productName;
        string price;
    }

    /**
     * @dev Mapping to store the product inventory based on the detected smart account address.
     */
    mapping(address => Product[]) public smartAccountToInventory; //gets the product inventory based on the detected smart account address

    //-----------------------------
    //DEFINE EVENTS
    //-----------------------------

    /**
     * @dev Event triggered when a product is added to the inventory.
     * @param smartAccountAddress The address of the smart account.
     * @param productPicCID The CID of the uploaded image content of the product.
     * @param productName The name of the product.
     * @param price The price of the product.
     */
    event ProductAdded(
        address indexed smartAccountAddress,
        string productPicCID,
        string productName,
        string price
    );

    /**
     * @dev Event triggered when a product is removed from the inventory.
     * @param smartAccountAddress The address of the smart account.
     * @param productPicCID The CID of the uploaded image content of the product.
     * @param productName The name of the product.
     * @param price The price of the product.
     */
    event ProductRemoved(
        address indexed smartAccountAddress,
        string productPicCID,
        string productName,
        string price
    );

    //-----------------------------
    //DEFINE MODIFIERS
    //-----------------------------

    /**
     * @dev Modifier to restrict function access to only smart accounts.
     * It checks if the caller is the original sender of the transaction.
     */
    modifier onlySmartAccount() {
        require(
            msg.sender == tx.origin,
            "Only smart account can call this function"
        );
        _;
    }

    //-----------------------------
    //DEFINE FUNCTIONS
    //-----------------------------
    //TODO: function to post product details to different chains at once (hyperlane)
    //TODO: function to fetch product details from different chain at once, getProduct(address) -> Product[] (hyperlane)
    //TODO: post attestation as merchant to attestation contract in Sepolia (wormhole)
    //TODO: resolver contract to check that a merchant attestaion exists in Sepolia
    //TODO: function to make an attestation that bill paid (wormhole)
    //TODO: function to fetch attestation from sepolia (hyperlane)
}
