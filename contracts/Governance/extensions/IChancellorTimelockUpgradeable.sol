// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/IGovernorTimelock.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../IChancellorUpgradeable.sol";

/**
 * @dev Extension of the {IChancellorUpgradeable} for timelock supporting modules.
 *
 * _Available since V1.0._
 */
abstract contract IChancellorTimelockUpgradeable is
    Initializable,
    IChancellorUpgradeable
{
    function __IChancelorTimelock_init() internal onlyInitializing {}

    function __IChancelorTimelock_init_unchained() internal onlyInitializing {}

    event ProposalQueued(uint256 proposalId, uint256 eta);

    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);

    function timelock() public view virtual returns (address);

    function proposalEta(uint256 proposalId)
        public
        view
        virtual
        returns (uint256);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
