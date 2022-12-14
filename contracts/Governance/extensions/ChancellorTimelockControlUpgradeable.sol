// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.0.0) (Governance/ChancellorTimelockControlUpgradeable.sol)
// Uses OpenZeppelin Contracts and Libraries

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
import "./IChancellorTimelockUpgradeable.sol";
import "../ChancellorUpgradeable.sol";

/**
 * @dev Extension of {ChancellorUpgradeable} that binds the execution process to an instance of {TimelockControllerUpgradeable}. This adds a
 * delay, enforced by the {TimelockControllerUpgradeable} to all successful proposal (in addition to the voting duration). The
 * {ChancellorUpgradeable} needs the proposer (and ideally the executor) roles for the {ChancellorUpgradeable} to work properly.
 *
 * ChancellorTimeLockControlUpgradeable.sol modifies OpenZeppelin's GovernorTimelockControlUpgradeable.sol:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/governance/extensions/GovernorTimelockControlUpgradeable.sol
 * GovernorTimelockControlUpgradeable.sol source code copyright OpenZeppelin licensed under the MIT License.
 * Modified by RoyalDAO.
 *
 * Changes: At this point, only naming
 *
 * _Available since v1.0._
 */
abstract contract ChancellorTimelockControlUpgradeable is
    Initializable,
    IChancellorTimelockUpgradeable,
    ChancellorUpgradeable
{
    TimelockControllerUpgradeable private _timelock;
    mapping(uint256 => bytes32) private _timelockIds;

    /**
     * @dev Emitted when the timelock controller used for proposal execution is modified.
     */
    event TimelockChange(address oldTimelock, address newTimelock);

    /**
     * @dev Set the timelock.
     */
    function __ChancellorTimelockControl_init(
        TimelockControllerUpgradeable timelockAddress
    ) internal onlyInitializing {
        __ChancellorTimelockControl_init_unchained(timelockAddress);
    }

    function __ChancellorTimelockControl_init_unchained(
        TimelockControllerUpgradeable timelockAddress
    ) internal onlyInitializing {
        _updateTimelock(timelockAddress);
    }

    /**
     * @dev Function to queue a proposal to the timelock.
     */
    function queue(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            descriptionHash
        );

        require(
            state(proposalId) == ProposalState.Succeeded,
            "Chancellor: proposal not successful"
        );

        uint256 delay = _timelock.getMinDelay();
        _timelockIds[proposalId] = _timelock.hashOperationBatch(
            targets,
            values,
            calldatas,
            0,
            descriptionHash
        );
        _timelock.scheduleBatch(
            targets,
            values,
            calldatas,
            0,
            descriptionHash,
            delay
        );

        emit ProposalQueued(proposalId, block.timestamp + delay);

        return proposalId;
    }

    /**
     * @dev Overridden execute function that run the already queued proposal through the timelock.
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override {
        _timelock.executeBatch{value: msg.value}(
            targets,
            values,
            calldatas,
            0,
            descriptionHash
        );
    }

    /**
     * @dev Overridden version of the {Chancellor-_cancel} function to cancel the timelocked proposal if it as already
     * been queued.
     */
    // This function can reenter through the external call to the timelock, but we assume the timelock is trusted and
    // well behaved (according to TimelockController) and this will not happen.
    // slither-disable-next-line reentrancy-no-eth
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(
            targets,
            values,
            calldatas,
            descriptionHash
        );

        if (_timelockIds[proposalId] != 0) {
            _timelock.cancel(_timelockIds[proposalId]);
            delete _timelockIds[proposalId];
        }

        return proposalId;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ChancellorUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IChancellorTimelockUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Overridden version of the {Chancellor-state} function with added support for the `Queued` status.
     */
    function state(uint256 proposalId)
        public
        view
        virtual
        override(IChancellorUpgradeable, ChancellorUpgradeable)
        returns (ProposalState)
    {
        ProposalState status = super.state(proposalId);

        if (status != ProposalState.Succeeded) {
            return status;
        }

        // core tracks execution, so we just have to check if successful proposal have been queued.
        bytes32 queueid = _timelockIds[proposalId];
        if (queueid == bytes32(0)) {
            return status;
        } else if (_timelock.isOperationDone(queueid)) {
            return ProposalState.Executed;
        } else if (_timelock.isOperationPending(queueid)) {
            return ProposalState.Queued;
        } else {
            return ProposalState.Canceled;
        }
    }

    /**
     * @dev Public accessor to check the address of the timelock
     */
    function timelock() public view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public accessor to check the eta of a queued proposal
     */
    function proposalEta(uint256 proposalId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 eta = _timelock.getTimestamp(_timelockIds[proposalId]);
        return eta == 1 ? 0 : eta; // _DONE_TIMESTAMP (1) should be replaced with a 0 value
    }

    /**
     * @dev Address through which the Chancellor executes action. In this case, the timelock.
     */
    function _executor() internal view virtual override returns (address) {
        return address(_timelock);
    }

    /**
     * @dev Public endpoint to update the underlying timelock instance. Restricted to the timelock itself, so updates
     * must be proposed, scheduled, and executed through Chancellor proposals.
     *
     * CAUTION: It is not recommended to change the timelock while there are other queued Chancellor proposals.
     */
    function updateTimelock(TimelockControllerUpgradeable newTimelock)
        external
        virtual
        onlyChancellor
    {
        _updateTimelock(newTimelock);
    }

    function _updateTimelock(TimelockControllerUpgradeable newTimelock)
        private
    {
        emit TimelockChange(address(_timelock), address(newTimelock));
        _timelock = newTimelock;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
