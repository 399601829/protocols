/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "../../../lib/AddressSet.sol";
import "../../../lib/Claimable.sol";
import "../../security/GuardianUtils.sol";

import "../../security/SecurityModule.sol";


/// @title GenericDAppModule
/// @dev GenericDAppModule allows wallet owners to transact directly or through meta
///      transactions on any whitelisted dApps. The transaction data must be appended
///      with the wallet address and then the dApp's address.
contract GenericDAppModule is Claimable, AddressSet, SecurityModule
{
    enum SecuritySetting
    {
        Owner,
        Majority
    }

    bytes32 internal constant DAPPS = keccak256("__DAPP__");

    event DAppEnabled(address indexed dapp, bool enabled);

    mapping (address => SecuritySetting) public securitySettings;
    mapping (address => mapping(address => bool)) public approvedDApps;

    modifier onlyApprovedDapp(
        address          wallet,
        address          dapp
        )
    {
        require(isDAppApproved(wallet, dapp), "DAPP_NOT_APPROVED");
        _;
    }

    modifier onlyWhenAuthorized(
        address           wallet,
        address[] memory  signers
        )
    {
        SecuritySetting securitySetting = securitySettings[wallet];
        if (securitySetting == SecuritySetting.Owner) {
            address walletOwner = Wallet(wallet).owner();
            require(
                msg.sender == walletOwner ||
                signers.length == 1 && signers[0] == walletOwner,
                "UNAUTHORIZED"
            );
        } else if(securitySetting == SecuritySetting.Majority) {
            GuardianUtils.requireSufficientSigners(
                securityStore,
                wallet,
                signers,
                GuardianUtils.SigRequirement.OwnerRequired
            );
        } else {
            revert("UNKNOWN_SECURITY");
        }
        _;
    }

    constructor(Controller _controller)
        public
        Claimable()
        SecurityModule(_controller)
    {
    }

    function enableDApp(address dapp)
        external
        onlyOwner
    {
        require(
            !controller.moduleRegistry().isModuleRegistered(dapp),
            "MODULE_NOT_SUPPORTED"
        );
        require(
            !controller.walletRegistry().isWalletRegistered(dapp),
            "WALLET_NOT_SUPPORTED"
        );
        addAddressToSet(DAPPS, dapp, true);
        emit DAppEnabled(dapp, true);
    }

    function disableDApp(address dapp)
        external
        onlyOwner
    {
        removeAddressFromSet(DAPPS, dapp);
        emit DAppEnabled(dapp, false);
    }

    function isDAppEnabled(address dapp)
        public
        view
        returns (bool)
    {
        return isAddressInSet(DAPPS, dapp);
    }

    function enabledDApps()
        public
        view
        returns (address[] memory)
    {
        return addressesInSet(DAPPS);
    }

    function setSecurity(
        address            wallet,
        address[] calldata signers,
        uint8              _securitySetting
        )
        external
        nonReentrant
        onlyFromMetaTxOrWalletOwner(wallet)
        onlyWhenWalletUnlocked(wallet)
        onlyWhenAuthorized(wallet, signers)
    {
        securitySettings[wallet] = SecuritySetting(_securitySetting);
    }

    function setDAppApproved(
        address            wallet,
        address[] calldata signers,
        address            dapp,
        bool               approved
        )
        external
        nonReentrant
        onlyFromMetaTxOrWalletOwner(wallet)
        onlyWhenWalletUnlocked(wallet)
        onlyWhenAuthorized(wallet, signers)
    {
        approvedDApps[wallet][dapp] = approved;
    }

    function isDAppApproved(
        address wallet,
        address dapp
        )
        public
        view
        returns (bool approved)
    {
        SecuritySetting securitySetting = securitySettings[wallet];
        if (securitySetting == SecuritySetting.Owner) {
            approved = isDAppEnabled(dapp);
        } else if(securitySetting == SecuritySetting.Majority) {
            approved = isDAppEnabled(dapp) && approvedDApps[wallet][dapp];
        } else {
            revert("UNKNOWN_SECURITY");
        }
    }

    function callDApp(
        address          wallet,
        address          dapp,
        uint             value,
        bytes   calldata data
        )
        external
        nonReentrant
        onlyFromMetaTxOrWalletOwner(wallet)
        onlyWhenWalletUnlocked(wallet)
        onlyApprovedDapp(wallet, dapp)
    {
        transactCall(wallet, dapp, value, data);
    }

    function approveERC20(
        address wallet,
        address dapp,
        address token,
        uint    amount
        )
        external
        nonReentrant
        onlyFromMetaTxOrWalletOwner(wallet)
        onlyWhenWalletUnlocked(wallet)
        onlyApprovedDapp(wallet, dapp)
    {
        bytes memory txData = abi.encodeWithSelector(
            ERC20(token).approve.selector,
            dapp,
            amount
        );
        transactCall(wallet, token, 0, txData);
    }

    function extractMetaTxSigners(
        address        wallet,
        bytes4         method,
        bytes   memory data
        )
        internal
        view
        returns (address[] memory signers)
    {
        if (method == this.setDAppApproved.selector ||
            method == this.setSecurity.selector) {
            return extractAddressesFromCallData(data, 1);
        } else {
            signers = new address[](1);
            signers[0] = Wallet(wallet).owner();
        }
    }
}
