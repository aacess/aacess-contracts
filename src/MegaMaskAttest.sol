// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//------------------------
//IMPORT EXTERNAL PACKAGES
//------------------------
import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";

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
    ) external payable returns (bytes32);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which can receive Wormhole messages.
 */
interface IWormholeReceiver {
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;
}

/**
 * @title MegaMask
 * @dev A smart contract for managing product inventory and attestation on different chains.
 */
contract MegaMaskAttest is IEAS, IWormholeReceiver {
    //-----------------------------
    //DEFINE VARIABLES & CONSTANTS
    //-----------------------------
    address public ieasAddress;
    address public wormholeRelayerAddress;
    uint256 constant GAS_LIMIT = 50_000;

    IEAS public eas;
    IWormholeRelayer public immutable wormholeRelayer;

    //-----------------------------
    //DEFINE EVENTS
    //-----------------------------

    // another event to say that the attestation is posted to Sepolia
    event AttestationPostedToSepolia(
        address attester,
        bytes32 schema,
        address indexed recipient,
        uint64 expirationTime,
        bool revocable,
        bytes32 indexed refUID,
        bytes indexed data,
        uint256 value
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
    constructor(address _wormholeRelayerAddress, address _ieasAddress) {
        wormholeRelayerAddress = _wormholeRelayerAddress;
        ieasAddress = _ieasAddress;
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
    function attest(
        AttestationRequest memory request
    ) external payable override returns (bytes32) {
        emit AttestationPostedToSepolia(
            msg.sender,
            request.schema,
            request.data.recipient,
            request.data.expirationTime,
            request.data.revocable,
            request.data.refUID,
            request.data.data,
            request.data.value
        );

        return eas.attest(request);
    }

    //-----------------------------
    //DEFINE GETTER FUNCTIONS
    //-----------------------------

    //-------------------------
    //DEFINE INTERNAL FUNCTIONS
    //-------------------------
    function _updateInstances() internal {
        wormholeRelayer = IWormholeRelayer(wormholeRelayerAddress);
        eas = IEAS(ieasAddress);
    }

    //-------------------------
    //DEFINE EXTERNAL FUNCTIONS
    //-------------------------
    //change the gas amount
    function changeGasAmount(uint256 _gasAmount) external {
        gasAmount = _gasAmount;
    }

    /**
     * @notice Returns the cost (in wei) of a greeting
     */
    function quoteCrossChainGreeting(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        // Cost of requesting a message to be sent to
        // chain 'targetChain' with a gasLimit of 'GAS_LIMIT'
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    /**
     * @notice Updates the list of 'greetings'
     * and emits a 'GreetingReceived' event with 'greeting'
     * on the HelloWormhole contract at
     * chain 'targetChain' and address 'targetAddress'
     */
    // function sendCrossChainGreeting(
    //     uint16 targetChain,
    //     address targetAddress,
    //     string memory greeting
    // ) public payable {
    //     bytes memory payload = abi.encode(greeting, msg.sender);
    //     uint256 cost = quoteCrossChainGreeting(targetChain);
    //     require(msg.value == cost, "Incorrect payment");
    //     wormholeRelayer.sendPayloadToEvm{value: cost}(
    //         targetChain,
    //         targetAddress,
    //         payload,
    //         0, // no receiver value needed
    //         GAS_LIMIT
    //     );
    // }

    //this is used to post attestation to Sepolia
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

    receive() external payable {}

    fallback() external payable {}
}
