//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//------------------------
//IMPORT EXTERNAL PACKAGES
//------------------------
import "aacess-contracts/lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import "aacess-contracts/lib/wormhole-solidity-sdk/src/interfaces/IWormholeReceiver.sol";

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
    IWormholeRelayer public wormholeRelayer;

    mapping(bytes32 => bool) public seenDeliveryVaaHashes;

    string public latestAttestation;

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
        uint256 value,
        bytes32 attestationHash
    );

    event AttestationReceived(
        string greeting,
        uint16 sourceChain,
        address sender
    );

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

    //function to change the wormhole relayer address
    function changeWormholeRelayerAddress(
        address _wormholeRelayerAddress
    ) external {
        wormholeRelayerAddress = _wormholeRelayerAddress;
        _updateInstances();
    }

    //setter function to add product to inventory
    function attest(
        AttestationRequest memory request
    ) public payable override returns (bytes32) {
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
    function attestCalldata(
        bytes calldata request
    ) external payable returns (bytes32) {
        bytes memory slicedRequest = new bytes(request.length - 4);
        for (uint256 i = 4; i < request.length; i++) {
            slicedRequest[i - 4] = request[i];
        }

        AttestationRequest memory requestDecoded = abi.decode(
            slicedRequest,
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
        wormholeRelayer = IWormholeRelayer(wormholeRelayerAddress);
        eas = IEAS(ieasAddress);
    }

    //-------------------------
    //DEFINE EXTERNAL FUNCTIONS
    //-------------------------

    function quoteCrossChainAttestation(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    function sendCrossChainAttestation(
        uint16 targetChain,
        address targetAddress,
        bytes calldata request
    ) public {
        uint256 cost = quoteCrossChainAttestation(targetChain);
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(request),
            0, // no receiver value needed since we're just passing a message
            GAS_LIMIT
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32, // address that called 'sendPayloadToEvm' (HelloWormhole contract address)
        uint16 sourceChain,
        bytes32 deliveryHash // this can be stored in a mapping deliveryHash => bool to prevent duplicate deliveries
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");

        // Ensure no duplicate deliveries
        require(
            !seenDeliveryVaaHashes[deliveryHash],
            "Message already processed"
        );

        //emit an event to say that the message is received
        emit AttestationReceived(string(payload), sourceChain, msg.sender);

        // Mark the delivery as seen
        seenDeliveryVaaHashes[deliveryHash] = true;

        // Parse the payload and do the corresponding actions!
        bytes memory slicedPayload = new bytes(payload.length - 4);
        for (uint256 i = 4; i < payload.length; i++) {
            slicedPayload[i - 4] = payload[i];
        }

        AttestationRequest memory request = abi.decode(
            slicedPayload,
            (AttestationRequest)
        );

        // Post the attestation to Sepolia
        bytes32 attestationHash = eas.attest(request);

        // Emit an event to say that the attestation is posted to Sepolia
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
