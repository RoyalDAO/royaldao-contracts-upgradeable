// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorTimelockControl.sol)

pragma solidity ^0.8.0;

import "./IChancelorSenateUpgradeable.sol";
import "../ChancelorUpgradeable.sol";
import "../SenateUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Extension of {Chancelor} that binds the execution process to an instance of {TimelockController}. This adds a
 * delay, enforced by the {TimelockController} to all successful proposal (in addition to the voting duration). The
 * {Chancelor} needs the proposer (and ideally the executor) roles for the {Chancelor} to work properly.
 *
 * Using this model means the proposal will be operated by the {TimelockController} and not by the {Chancelor}. Thus,
 * the assets and permissions must be attached to the {TimelockController}. Any asset sent to the {Chancelor} will be
 * inaccessible.
 *
 * WARNING: Setting up the TimelockController to have additional proposers besides the Chancelor is very risky, as it
 * grants them powers that they must be trusted or known not to use: 1) {onlyChancelor} functions like {relay} are
 * available to them through the timelock, and 2) approved Chancelor proposals can be blocked by them, effectively
 * executing a Denial of Service attack. This risk will be mitigated in a future release.
 *
 * _Available since v4.3._
 */
abstract contract ChancelorSenateControlUpgradeable is
    Initializable,
    IChancelorSenateUpgradeable,
    ChancelorUpgradeable
{
    SenateUpgradeable private _senate;

    /**
     * @dev Set the timelock.
     */
    function __ChancelorSenateControl_init(SenateUpgradeable senateAddress)
        internal
        onlyInitializing
    {
        __ChancelorSenateControl_init_unchained(senateAddress);
    }

    function __ChancelorSenateControl_init_unchained(
        SenateUpgradeable senateAddress
    ) internal onlyInitializing {
        _updateSenate(senateAddress);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ChancelorUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IChancelorSenateUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function senate() public view virtual override returns (address) {
        return address(_senate);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled, and executed through Chancelor proposals.
     *
     * CAUTION: It is not recommended to change the timelock while there are other queued Chancelor proposals.
     */
    function updateSenate(SenateUpgradeable newSenate)
        external
        virtual
        onlyChancelor
    {
        _updateSenate(newSenate);
    }

    function _updateSenate(SenateUpgradeable newSenate) private {
        emit SenateChange(address(_senate), address(newSenate));
        _senate = newSenate;
    }

    function votingDelay() public view virtual override returns (uint256) {
        return _senate.votingDelay();
    }

    function votingPeriod() public view virtual override returns (uint256) {
        return _senate.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _senate.quorum(blockNumber);
    }

    function proposalThreshold()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _senate.proposalThreshold();
    }

    function getSettings()
        public
        view
        virtual
        override
        returns (
            uint256 currProposalThreshold,
            uint256 currVotingDelay,
            uint256 currVotingPeriod
        )
    {
        return _senate.getSettings();
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return _senate.getVotes(account, blockNumber, _defaultParams());
    }

    /**
     * @dev Check if `account` at a specific `blockNumber` reachs the treshold.
     */
    function _checkTresholdReached(address account, uint256 blockNumber)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _senate.checkTresholdReached(account, blockNumber);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
