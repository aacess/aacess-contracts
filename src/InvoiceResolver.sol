// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {SchemaResolver} from "./SchemaResolver.sol";

import {IEAS, Attestation} from "./interfaces/IEAS.sol";

import {MegaMaskProduct} from "./MegaMaskProduct.sol";

/**
 * @title A sample schema resolver that checks whether the attestation is from a specific attester.
 */
contract InvoiceResolver is SchemaResolver {
    // Post public postContract;
    constructor(IEAS _eas) SchemaResolver(_eas) {}

    /**
     * @dev Check that the attestation exists
     */
    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal override returns (bool) {
        //WIP: check if the attestation from the merchant exists
    }

    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }
}
