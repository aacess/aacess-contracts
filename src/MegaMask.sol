// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//------------------------
//IMPORT EXTERNAL PACKAGES
//------------------------
import {IMailbox} from "./interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "./interfaces/IInterchainGasPaymaster.sol";

/**
 * @title MegaMask
 * @dev A smart contract for managing product inventory and attestation on different chains.
 */
contract MegaMask {
    //-----------------------------
    //DEFINE VARIABLES & CONSTANTS
    //-----------------------------
    address public interchainGasPaymasterAddress;
    address public mailboxAddress;

    uint256 gasAmount;

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

    //another variable to store the chain ids of the chains where the product details are propagated
    uint256[] public chainIdsToPropagateTo;

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
    event ProductAddedToOriginChain(
        address indexed smartAccountAddress,
        string productPicCID,
        string productName,
        string price,
        uint256 index
    );

    // another event to say that the product details are propagated to different chains
    event ProductPropagatedToDifferentChains(
        address indexed smartAccountAddress,
        string productPicCID,
        string productName,
        string price,
        uint256 index
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

    /**
     * @dev Event triggered when the interchain gas paymaster address is updated.
     * @param newInterchainGasPaymasterAddress The new interchain gas paymaster address.
     */
    event InterchainGasPaymasterUpdated(
        address newInterchainGasPaymasterAddress
    );

    /**
     * @dev Event triggered when the mailbox address is updated.
     * @param newMailboxAddress The new mailbox address.
     */
    event MailboxUpdated(address newMailboxAddress);

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
    //CONSTRUCTOR FUNCTION
    //-----------------------------
    constructor(
        address _interchainGasPaymasterAddress,
        address _mailboxAddress
    ) {
        interchainGasPaymasterAddress = _interchainGasPaymasterAddress;
        mailboxAddress = _mailboxAddress;
    }

    IMailbox mailbox = IMailbox(mailboxAddress);
    IInterchainGasPaymaster igp =
        IInterchainGasPaymaster(interchainGasPaymasterAddress);

    //-----------------------------
    //DEFINE SETTER FUNCTIONS
    //TODO: function to post product details to different chains at once (hyperlane)
    //TODO: function to fetch product details from current chain, getProduct(address) -> Product[] (hyperlane)
    //TODO: post attestation as merchant to attestation contract in Sepolia (wormhole)
    //TODO: resolver contract to check that a merchant attestaion exists in Sepolia
    //TODO: function to make an attestation that bill paid (wormhole)
    //TODO: function to fetch attestation from sepolia (hyperlane)
    //-----------------------------

    //setter function to add product to inventory
    function addProduct(
        string memory _productPicCID,
        string memory _productName,
        string memory _price
    ) public onlySmartAccount {
        //create a new product
        Product memory newProduct = Product({
            productPicCID: _productPicCID,
            productName: _productName,
            price: _price
        });

        //add the new product to the inventory
        smartAccountToInventory[msg.sender].push(newProduct);

        //emit event and also mention which index the product is added to
        emit ProductAddedToOriginChain(
            msg.sender,
            _productPicCID,
            _productName,
            _price,
            smartAccountToInventory[msg.sender].length - 1
        );

        //call internal function to propagate product details to different chains
        _propagateProductDetailsToDifferentChains(
            _productPicCID,
            _productName,
            _price
        );
    }

    //setter function to add multiple products to inventory
    function addMultipleProducts(
        string[] memory _productPicCIDs,
        string[] memory _productNames,
        string[] memory _prices
    ) external onlySmartAccount {
        //loop through the product details and add them to the inventory
        for (uint256 i = 0; i < _productPicCIDs.length; i++) {
            addProduct(_productPicCIDs[i], _productNames[i], _prices[i]);
        }
    }

    //-----------------------------
    //DEFINE GETTER FUNCTIONS
    //-----------------------------

    //-----------------------------
    //DEFINE INTERNAL FUNCTIONS
    //-----------------------------
    //setter function to update the chain ids to propagate to
    function _updateChainIdsToPropagateTo(
        uint256[] memory _chainIdsToPropagateTo
    ) external {
        chainIdsToPropagateTo = _chainIdsToPropagateTo;
    }

    //setter function to propagate product details to different chains
    function _propagateProductDetailsToDifferentChains(
        string memory _productPicCID,
        string memory _productName,
        string memory _price
    ) internal {
        //loop through the chain ids to propagate to
        for (uint256 i = 0; i < chainIdsToPropagateTo.length; i++) {
            //emit event and also mention which index the product is added to
            emit ProductPropagatedToDifferentChains(
                msg.sender,
                _productPicCID,
                _productName,
                _price,
                smartAccountToInventory[msg.sender].length - 1
            );
        }
    }

    //change the gas amount
    function _changeGasAmount(uint256 _gasAmount) external {
        gasAmount = _gasAmount;
    }

    //change the interchain gas paymaster address
    function changeInterchainGasPaymasterAddress(
        address _interchainGasPaymasterAddress
    ) external {
        interchainGasPaymasterAddress = _interchainGasPaymasterAddress;
        emit InterchainGasPaymasterUpdated(_interchainGasPaymasterAddress);
    }

    //change the mailbox address
    function changeMailboxAddress(address _mailboxAddress) external {
        mailboxAddress = _mailboxAddress;
        emit MailboxUpdated(_mailboxAddress);
    }

    //this is used to call AttestRecipient contract on Arbitrum Goerli
    function _sendInterchainCall(
        uint32 destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external payable {
        bytes32 messageId = mailbox.dispatch(
            destinationDomain,
            _recipientAddress,
            _messageBody
        );
        igp.payForGas{value: msg.value}(
            messageId, // The ID of the message that was just dispatched
            destinationDomain, // The destination domain of the message
            gasAmount, // 550k gas to use in the recipient's handle function
            msg.sender // refunds go to msg.sender, who paid the msg.value
        );
    }
}
