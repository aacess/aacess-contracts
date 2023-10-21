// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMessageRecipient} from "./interfaces/IMessageRecipient.sol";
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "./interfaces/IInterchainSecurityModule.sol";

interface IMegaMask {
    // Functions
    function addProduct(
        string memory _productPicCID,
        string memory _productName,
        string memory _price
    ) external payable;

    function addMultipleProducts(
        string[] memory _productPicCIDs,
        string[] memory _productNames,
        string[] memory _prices
    ) external payable;
}

contract MegaMaskRecipient is
    IMessageRecipient,
    ISpecifiesInterchainSecurityModule,
    IMegaMask
{
    address public megaMaskAddress;
    address public mailboxAddress;

    IMegaMask public megaMask;
    IInterchainSecurityModule public interchainSecurityModule;

    bytes32 public lastSender;
    bytes public lastData;

    address public lastCaller;
    string public lastCallMessage;

    event ReceivedMessage(
        uint32 indexed origin,
        bytes32 indexed sender,
        string message
    );

    event ReceivedAddProductRequest(
        address indexed caller,
        string productPicCID,
        string productName,
        string price
    );

    event ReceivedAddMultipleProductsRequest(
        address indexed caller,
        string[] productPicCIDs,
        string[] productNames,
        string[] prices
    );

    // for access control on handle implementations
    modifier onlyMailbox() {
        require(msg.sender == mailboxAddress, "Caller is not mailbox");
        _;
    }

    constructor(address _mailbox, address _megaMaskAddress) {
        mailboxAddress = _mailbox;
        megaMaskAddress = _megaMaskAddress;
        _updateInstances();
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external virtual override onlyMailbox {
        emit ReceivedMessage(_origin, _sender, string(_data));
        bytes4 functionSignature = abi.decode(_data[:4], (bytes4));
        if (functionSignature == this.addProduct.selector) {
            (
                string memory _productPicCID,
                string memory _productName,
                string memory _price
            ) = abi.decode(_data[4:], (string, string, string));
            addProduct(_productPicCID, _productName, _price);
        } else if (functionSignature == this.addMultipleProducts.selector) {
            (
                string[] memory _productPicCIDs,
                string[] memory _productNames,
                string[] memory _prices
            ) = abi.decode(_data[4:], (string[], string[], string[]));
            addMultipleProducts(_productPicCIDs, _productNames, _prices);
        } else {
            revert("Unknown function");
        }
    }

    function setInterchainSecurityModule(address _ism) external {
        interchainSecurityModule = IInterchainSecurityModule(_ism);
    }

    function getInterchainSecurityModule() external view returns (address) {
        return address(interchainSecurityModule);
    }

    function setMailbox(address _mailbox) external {
        mailboxAddress = _mailbox;
    }

    function getMailbox() external view returns (address) {
        return mailboxAddress;
    }

    function setMegaMaskAddress(address _megaMaskAddress) external {
        megaMaskAddress = _megaMaskAddress;
        _updateInstances();
    }

    function getMegaMaskAddress() external view returns (address) {
        return megaMaskAddress;
    }

    function addProduct(
        string memory _productPicCID,
        string memory _productName,
        string memory _price
    ) public payable {
        _updateInstances();
        emit ReceivedAddProductRequest(
            msg.sender,
            _productPicCID,
            _productName,
            _price
        );

        return
            megaMask.addProduct{value: msg.value}(
                _productPicCID,
                _productName,
                _price
            );
    }

    function addMultipleProducts(
        string[] memory _productPicCIDs,
        string[] memory _productNames,
        string[] memory _prices
    ) public payable {
        _updateInstances();
        emit ReceivedAddMultipleProductsRequest(
            msg.sender,
            _productPicCIDs,
            _productNames,
            _prices
        );

        return
            megaMask.addMultipleProducts{value: msg.value}(
                _productPicCIDs,
                _productNames,
                _prices
            );
    }

    function _updateInstances() internal {
        megaMask = IMegaMask(megaMaskAddress);
    }
}
