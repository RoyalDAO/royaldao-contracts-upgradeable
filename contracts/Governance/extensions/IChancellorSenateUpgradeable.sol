// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.0.0) (Governance/extensions/IChancellorSenateUpgradeable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../IChancellorUpgradeable.sol";

/**
 * @dev Extension of the {IChancellorUpgradeable} for senate supporting modules.
 *
 * _Available since v1.0._
 */
abstract contract IChancellorSenateUpgradeable is
    Initializable,
    IChancellorUpgradeable
{
    function __ISenateTimelock_init() internal onlyInitializing {}

    function __ISenateTimelock_init_unchained() internal onlyInitializing {}

    /**
     * @dev Emitted when the senate controller used for members control is modified.
     */
    event SenateChange(address oldSenate, address newSenate);

    function senate() public view virtual returns (address);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
