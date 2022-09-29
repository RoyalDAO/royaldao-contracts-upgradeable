// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "../IChancelorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Extension of the {IChancelor} for timelock supporting modules.
 *
 * _Available since v4.3._
 */
abstract contract IChancelorSenateUpgradeable is
    Initializable,
    IChancelorUpgradeable
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
