//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//------------------------
//IMPORT EXTERNAL PACKAGES
//------------------------
import {IMessageRecipient} from "./interfaces/IMessageRecipient.sol";
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "./interfaces/IInterchainSecurityModule.sol";
import {IMailbox} from "./interfaces/IMailbox.sol";
import {IInterchainGasPaymaster} from "./interfaces/IInterchainGasPaymaster.sol";

interface IEAS {
    /// @notice A struct representing the arguments of the attestation request.
    struct AttestationRequestData {
        address recipient; // The recipient of the attestation.
        uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
        bool revocable; // Whether the attestation is revocable.
        bytes32 refUID; // The UID of the related attestation.
        bytes data; // Custom attestation data.
        uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
    }

    /// @notice A struct representing the full arguments of the attestation request.
    struct AttestationRequest {
        bytes32 schema; // The unique identifier of the schema.
        AttestationRequestData data; // The arguments of the attestation request.
    }

    function attest(
        AttestationRequest calldata request
    ) external returns (bytes32);
}

/**
 * @title MegaMask
 * @dev A smart contract for managing product inventory and attestation on different chains.
 */
contract MegaMaskAttest is IEAS, IMessageRecipient {
    //-----------------------------
    //DEFINE VARIABLES & CONSTANTS
    //-----------------------------
    address public ieasAddress;
    address public interchainGasPaymasterAddress;
    address public mailboxAddress;

    uint256 gasAmount = 100000;

    IMailbox public mailbox;
    IInterchainGasPaymaster public igp;
    IEAS public eas;

    //-----------------------------
    //DEFINE EVENTS
    //-----------------------------

    //event to say that the product is added
    event ReceivedMessage(
        uint32 indexed origin,
        bytes32 indexed sender,
        string message
    );

    // another event to say that the attestation is posted to Sepolia
    event AttestationPostedToSepolia(
        address attester,
        bytes32 schema,
        address indexed recipient,
        uint64 expirationTime,
        bool revocable,
        bytes32 indexed refUID,
        bytes indexed data,
        uint256 value,
        bytes32 attestationHash
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
        address _mailboxAddress,
        address _ieasAddress
    ) {
        interchainGasPaymasterAddress = _interchainGasPaymasterAddress;
        mailboxAddress = _mailboxAddress;
        ieasAddress = _ieasAddress;
        _updateInstances(); // update the instances upon deployment
    }

    //setter function to add product to inventory
    function attest(
        AttestationRequest memory request
    ) public returns (bytes32) {
        // Post the attestation to Sepolia
        bytes32 attestationHash = eas.attest(request);

        emit AttestationPostedToSepolia(
            msg.sender,
            request.schema,
            request.data.recipient,
            request.data.expirationTime,
            request.data.revocable,
            request.data.refUID,
            request.data.data,
            request.data.value,
            attestationHash
        );

        return attestationHash;
    }

    //another attest function but accept a calldata, decode it and call the above function
    function attestCalldata(bytes calldata request) public returns (bytes32) {
        AttestationRequest memory requestDecoded = abi.decode(
            request[4:],
            (AttestationRequest)
        );

        return attest(requestDecoded);
    }

    //-----------------------------
    //DEFINE GETTER FUNCTIONS
    //-----------------------------

    //-------------------------
    //DEFINE INTERNAL FUNCTIONS
    //-------------------------
    function _updateInstances() internal {
        mailbox = IMailbox(mailboxAddress);
        igp = IInterchainGasPaymaster(interchainGasPaymasterAddress);
        eas = IEAS(ieasAddress);
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

    //change the ieas address
    function changeIEASAddress(address _ieasAddress) external {
        ieasAddress = _ieasAddress;
        _updateInstances(); // Update instances after changing the address
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

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external virtual override {
        _updateInstances();
        emit ReceivedMessage(_origin, _sender, string(_data));

        // Post the attestation to Sepolia
        attestCalldata(_data);
    }

    //transfer function to transfer the funds to another contract
    function transferFunds(address payable _to, uint256 _amount) external {
        _to.transfer(_amount);
    }

    //get contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}

    fallback() external payable {}
}
