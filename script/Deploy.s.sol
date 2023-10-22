// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MegaMaskProduct} from "../src/MegaMaskProduct.sol";
import {MegaMaskAttestHyperlane} from "../src/MegaMaskAttestHyperlane.sol";
import {MegaMaskAttestWormhole} from "../src/MegaMaskAttestWormhole.sol";
import {MegaMaskProductRecipient} from "../src/MegaMaskProductRecipient.sol";

contract Deploy is Script {
    //define EAS contract address
    address EAS = address(0);
    address INTERCHAIN_GAS_PAYMASTER = address(0);
    address MAILBOX = address(0);
    address WORMHOLE_RELAYER = address(0);

    function run() external {
        // set up deployer
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        // log deployer data
        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        vm.startBroadcast(deployer);

        // deploy MegaMask product first
        MegaMaskProduct megaMaskProduct = new MegaMaskProduct(
            INTERCHAIN_GAS_PAYMASTER,
            MAILBOX
        );

        //then, deploy MegaMaskProductRecipient
        MegaMaskProductRecipient megaMaskProductRecipient = new MegaMaskProductRecipient(
                MAILBOX,
                address(megaMaskProduct)
            );

        //then, deploy MegaMaskAttestHyperlane
        MegaMaskAttestHyperlane megaMaskAttestHyperlane = new MegaMaskAttestHyperlane(
                INTERCHAIN_GAS_PAYMASTER,
                MAILBOX,
                EAS
            );

        //then, deploy MegaMaskAttestWormhole
        MegaMaskAttestWormhole megaMaskAttestWormhole = new MegaMaskAttestWormhole(
                WORMHOLE_RELAYER,
                EAS
            );

        vm.stopBroadcast();

        // log deployment data
        console2.log("MegaMaskProduct: ", address(megaMaskProduct));
        console2.log(
            "MegaMaskProductRecipient: ",
            address(megaMaskProductRecipient)
        );
        console2.log(
            "MegaMaskAttestHyperlane: ",
            address(megaMaskAttestHyperlane)
        );
        console2.log(
            "MegaMaskAttestWormhole: ",
            address(megaMaskAttestWormhole)
        );
    }
}
