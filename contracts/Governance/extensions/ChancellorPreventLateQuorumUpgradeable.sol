// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.0.0) (Governance/extensions/ChancellorPreventLateQuorum.sol)
// Uses OpenZeppelin Contracts and Libraries

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ChancellorUpgradeable.sol";

/**
 * @dev A module that ensures there is a minimum voting period after quorum is reached.
 *
 * ChancellorPreventLateQuorumUpgradeable.sol modifies OpenZeppelin's GovernorPreventLateQuorumUpgradeable.sol:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/governance/extensions/GovernorPreventLateQuorumUpgradeable.sol
 * GovernorPreventLateQuorumUpgradeable.sol source code copyright OpenZeppelin licensed under the MIT License.
 * Modified by RoyalDAO.
 *
 * _Available since v1.0._
 */
abstract contract ChancellorPreventLateQuorumUpgradeable is
    Initializable,
    ChancellorUpgradeable
{
    using SafeCastUpgradeable for uint256;
    using TimersUpgradeable for TimersUpgradeable.BlockNumber;

    uint64 private _voteExtension;
    mapping(uint256 => TimersUpgradeable.BlockNumber)
        private _extendedDeadlines;

    /// @dev Emitted when a proposal deadline is pushed back due to reaching quorum late in its voting period.
    event ProposalExtended(uint256 indexed proposalId, uint64 extendedDeadline);

    /// @dev Emitted when the {lateQuorumVoteExtension} parameter is changed.
    event LateQuorumVoteExtensionSet(
        uint64 oldVoteExtension,
        uint64 newVoteExtension
    );

    /**
     * @dev Initializes the vote extension parameter: the number of blocks that are required to pass since a proposal
     * reaches quorum until its voting period ends. If necessary the voting period will be extended beyond the one set
     * at proposal creation.
     */
    function __ChancelorPreventLateQuorum_init(uint64 initialVoteExtension)
        internal
        onlyInitializing
    {
        __ChancelorPreventLateQuorum_init_unchained(initialVoteExtension);
    }

    function __ChancelorPreventLateQuorum_init_unchained(
        uint64 initialVoteExtension
    ) internal onlyInitializing {
        _setLateQuorumVoteExtension(initialVoteExtension);
    }

    /**
     * @dev Changes the {lateQuorumVoteExtension}. This operation can only be performed by the governance executor,
     * generally through a governance proposal.
     *
     * Emits a {LateQuorumVoteExtensionSet} event.
     */
    function setLateQuorumVoteExtension(uint64 newVoteExtension)
        public
        virtual
        onlyChancellor
    {
        _setLateQuorumVoteExtension(newVoteExtension);
    }

    /**
     * @dev Returns the proposal deadline, which may have been extended beyond that set at proposal creation, if the
     * proposal reached quorum late in the voting period. See {ChancellorUpgradeable-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return
            MathUpgradeable.max(
                super.proposalDeadline(proposalId),
                _extendedDeadlines[proposalId].getDeadline()
            );
    }

    /**
     * @dev Returns the current value of the vote extension parameter: the number of blocks that are required to pass
     * from the time a proposal reaches quorum until its voting period ends.
     */
    function lateQuorumVoteExtension() public view virtual returns (uint64) {
        return _voteExtension;
    }

    /**
     * @dev Casts a vote and detects if it caused quorum to be reached, potentially extending the voting period. See
     * {ChancellorUpgradeable-_castVote}.
     *
     * May emit a {ProposalExtended} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual override returns (uint256) {
        uint256 result = super._castVote(
            proposalId,
            account,
            support,
            reason,
            params
        );

        TimersUpgradeable.BlockNumber
            storage extendedDeadline = _extendedDeadlines[proposalId];

        if (extendedDeadline.isUnset() && _quorumReached(proposalId)) {
            uint64 extendedDeadlineValue = block.number.toUint64() +
                lateQuorumVoteExtension();

            if (extendedDeadlineValue > proposalDeadline(proposalId)) {
                emit ProposalExtended(proposalId, extendedDeadlineValue);
            }

            extendedDeadline.setDeadline(extendedDeadlineValue);
        }

        return result;
    }

    /**
     * @dev Changes the {lateQuorumVoteExtension}. This is an internal function that can be exposed in a public function
     * like {setLateQuorumVoteExtension} if another access control mechanism is needed.
     *
     * Emits a {LateQuorumVoteExtensionSet} event.
     */
    function _setLateQuorumVoteExtension(uint64 newVoteExtension)
        internal
        virtual
    {
        emit LateQuorumVoteExtensionSet(_voteExtension, newVoteExtension);
        _voteExtension = newVoteExtension;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
