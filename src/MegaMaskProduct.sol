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
contract MegaMaskProduct {
    //-----------------------------
    //DEFINE VARIABLES & CONSTANTS
    //-----------------------------
    address public interchainGasPaymasterAddress;
    address public mailboxAddress;
    uint256 gasAmount = 100000;

    IMailbox public mailbox;
    IInterchainGasPaymaster public igp;
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

    struct ChainIdToRecipientContractAddress {
        uint32 chainId;
        bytes32 contractAddress;
    }

    mapping(uint256 => ChainIdToRecipientContractAddress)
        public chainIdToContractAddress;

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
        uint256 indexed chainId,
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

    //-----------------------------
    //CONSTRUCTOR FUNCTION
    //-----------------------------
    constructor(
        address _interchainGasPaymasterAddress,
        address _mailboxAddress
    ) {
        interchainGasPaymasterAddress = _interchainGasPaymasterAddress;
        mailboxAddress = _mailboxAddress;
        _updateInstances(); // update the instances upon deployment
    }

    //-----------------------------
    //DEFINE SETTER FUNCTIONS
    //TODO: function to post product details to different chains at once (hyperlane) DONE
    //TODO: function to fetch product details from current chain, getProduct(address) -> Product[] (hyperlane) DONE
    //TODO: post attestation as merchant to attestation contract in Sepolia (wormhole)
    //TODO: resolver contract to check that a merchant attestaion exists in Sepolia
    //TODO: function to make an attestation that bill paid (wormhole)
    //TODO: function to fetch attestation from sepolia (hyperlane)
    //-----------------------------

    //setter function to add product to inventory
    function addProduct(
        string memory _productPicCID,
        string memory _productName,
        string memory _price,
        address _requestor
    ) public {
        //create a new product
        Product memory newProduct = Product({
            productPicCID: _productPicCID,
            productName: _productName,
            price: _price
        });

        //add the new product to the inventory
        smartAccountToInventory[_requestor].push(newProduct);

        //emit event and also mention which index the product is added to
        emit ProductAddedToOriginChain(
            _requestor,
            _productPicCID,
            _productName,
            _price,
            smartAccountToInventory[_requestor].length - 1
        );
    }

    //-----------------------------
    //DEFINE GETTER FUNCTIONS
    //-----------------------------

    //getter function to get the product inventory
    function getProductInventory(
        address _smartAccountAddress
    ) public view returns (Product[] memory) {
        return smartAccountToInventory[_smartAccountAddress];
    }

    //getter function to get the product details
    function getProduct(
        address _smartAccountAddress,
        uint256 _productIndex
    ) public view returns (Product memory) {
        return smartAccountToInventory[_smartAccountAddress][_productIndex];
    }

    //-------------------------
    //DEFINE INTERNAL FUNCTIONS
    //-------------------------
    function _updateInstances() internal {
        mailbox = IMailbox(mailboxAddress);
        igp = IInterchainGasPaymaster(interchainGasPaymasterAddress);
    }

    //-------------------------
    //DEFINE EXTERNAL FUNCTIONS
    //-------------------------
    //change the gas amount
    function changeGasAmount(uint256 _gasAmount) external {
        gasAmount = _gasAmount;
    }

    //change the interchain gas paymaster address
    function changeInterchainGasPaymasterAddress(
        address _interchainGasPaymasterAddress
    ) external {
        interchainGasPaymasterAddress = _interchainGasPaymasterAddress;
        emit InterchainGasPaymasterUpdated(_interchainGasPaymasterAddress);
        _updateInstances(); // Update instances after changing the address
    }

    //change the mailbox address
    function changeMailboxAddress(address _mailboxAddress) external {
        mailboxAddress = _mailboxAddress;
        emit MailboxUpdated(_mailboxAddress);
        _updateInstances(); // Update instances after changing the address
    }

    //setter function to update the chain ids to propagate to, use the array to get the latest index to update the mapping
    function addChainIdToPropagateTo(
        uint32 _chainId,
        bytes32 _recipientContractAddress
    ) external {
        //check if the chain id already exists in the array
        for (uint256 i = 0; i < chainIdsToPropagateTo.length; i++) {
            //check if the chain id already exists in the array
            require(
                chainIdsToPropagateTo[i] != _chainId,
                "Chain ID already exists in the array"
            );
        }

        //add the chain id to the array
        chainIdsToPropagateTo.push(_chainId);

        //add the chain id and the contract address to the mapping
        chainIdToContractAddress[
            chainIdsToPropagateTo.length
        ] = ChainIdToRecipientContractAddress({
            chainId: _chainId,
            contractAddress: _recipientContractAddress
        });
    }

    //function to update the chain id to contract address mapping
    function updateChainIdToContractAddress(
        uint256 _index,
        uint32 _chainId,
        bytes32 _recipientContractAddress
    ) external {
        //update the chain id to contract address mapping
        chainIdToContractAddress[_index] = ChainIdToRecipientContractAddress({
            chainId: _chainId,
            contractAddress: _recipientContractAddress
        });
    }

    //function to propagate to other chains other than the origin chain, it accepts the origin chain ID so it knows which to skip, and also the product index
    function propagateToOtherChains(
        uint32 _originChainId,
        bytes calldata _data
    ) external {
        //loop through the chain ids to propagate to
        for (uint256 i = 1; i <= chainIdsToPropagateTo.length; i++) {
            //check if the chain id is not the origin chain id
            if (chainIdToContractAddress[i].chainId != _originChainId) {
                //call the sendInterchainCall function to send the interchain call
                sendInterchainCall(
                    chainIdToContractAddress[i].chainId,
                    chainIdToContractAddress[i].contractAddress,
                    _data
                );
            }
        }
    }

    //this is used to call AttestRecipient contract on Arbitrum Goerli
    function sendInterchainCall(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) public {
        _updateInstances(); // Ensure instances are up-to-date
        bytes32 messageId = mailbox.dispatch(
            _destinationDomain,
            _recipientAddress,
            _messageBody
        );

        // Get the required payment from the IGP.
        uint256 quote = igp.quoteGasPayment(_destinationDomain, gasAmount);

        igp.payForGas{value: quote}(
            messageId, // The ID of the message that was just dispatched
            _destinationDomain, // The destination domain of the message
            gasAmount, // 550k gas to use in the recipient's handle function
            address(this) // refunds go to msg.sender, who paid the msg.value
        );
    }

    //transfer function to transfer the funds to another contract
    function transferFunds(address payable _to, uint256 _amount) external {
        _to.transfer(_amount);
    }

    //get contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    //get the list of chain ids to propagate to
    function getChainIdsToPropagateTo()
        external
        view
        returns (uint256[] memory)
    {
        return chainIdsToPropagateTo;
    }

    //get the chain id to contract address mapping
    function getChainIdToContractAddress(
        uint256 _index
    ) external view returns (ChainIdToRecipientContractAddress memory) {
        return chainIdToContractAddress[_index];
    }

    receive() external payable {}
}
