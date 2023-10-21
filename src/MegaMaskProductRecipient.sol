// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IMessageRecipient} from "./interfaces/IMessageRecipient.sol";
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "./interfaces/IInterchainSecurityModule.sol";

interface IMegaMaskProduct {
    // Functions
    function addProduct(
        string memory _productPicCID,
        string memory _productName,
        string memory _price,
        address requestor
    ) external payable;
}

contract MegaMaskProductRecipient is
    IMessageRecipient,
    ISpecifiesInterchainSecurityModule,
    IMegaMaskProduct
{
    address public megaMaskAddress;
    address public mailboxAddress;

    IMegaMaskProduct public megaMask;
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
        string productPicCID,
        string productName,
        string price,
        address indexed requestor
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
        _updateInstances();
        emit ReceivedMessage(_origin, _sender, string(_data));
        //for now, ignore adding multiple products
        (
            string memory _productPicCID,
            string memory _productName,
            string memory _price,
            address _requestor
        ) = abi.decode(_data[4:], (string, string, string, address));

        emit ReceivedAddProductRequest(
            _productPicCID,
            _productName,
            _price,
            _requestor
        );

        megaMask.addProduct(_productPicCID, _productName, _price, _requestor);
        lastSender = _sender;
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
        string memory _price,
        address _requestor
    ) public payable {}

    function _updateInstances() internal {
        megaMask = IMegaMaskProduct(megaMaskAddress);
    }
}
