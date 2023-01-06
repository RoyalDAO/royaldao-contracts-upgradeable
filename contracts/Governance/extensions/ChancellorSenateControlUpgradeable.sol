// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.0.0) (Governance/extensions/ChancellorSenateControlUpgradeable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IChancellorSenateUpgradeable.sol";
import "../ChancellorUpgradeable.sol";
import "../SenateUpgradeable.sol";

/**
 * @dev Extension of {ChancellorUpgradeable} that binds the DAO to an instance of {SenateUpgradeable}. This adds a
 * new layer that controls the Members (tokens) that can participate in the DAO.
 *
 * _Available since v1.0._
 */
abstract contract ChancellorSenateControlUpgradeable is
    Initializable,
    IChancellorSenateUpgradeable,
    ChancellorUpgradeable
{
    SenateUpgradeable private _senate;

    /**
     * @dev Set the senate.
     */
    function __ChancellorSenateControl_init(SenateUpgradeable senateAddress)
        internal
        onlyInitializing
    {
        __ChancellorSenateControl_init_unchained(senateAddress);
    }

    function __ChancellorSenateControl_init_unchained(
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
        override(IERC165Upgradeable, ChancellorUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IChancellorSenateUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Public endpoint to update the underlying senate instance. Restricted to the DAO itself, so updates
     * must be proposed, scheduled (if using a timelock control), and executed through Chancellor proposals.
     *
     * CAUTION: It is not recommended to change the senate while there are active proposals.
     */
    function updateSenate(SenateUpgradeable newSenate)
        external
        virtual
        onlyChancellor
    {
        _updateSenate(newSenate);
    }

    /**
     * @dev Public accessor to check the address of the senate
     */
    function senate() public view virtual override returns (address) {
        return address(_senate);
    }

    /**
     * @dev Public endpoint to retrieve voting delay from senate
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _senate.votingDelay();
    }

    /**
     * @dev Public endpoint to retrieve voting period from senate
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _senate.votingPeriod();
    }

    /**
     * @dev Public endpoint to retrieve quorum at given block from senate
     */
    function quorum(uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _senate.quorum(blockNumber);
    }

    /**
     * @dev Public endpoint to retrieve proposal Threshold from senate
     */
    function proposalThreshold()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _senate.proposalThreshold();
    }

    /**
     * @dev Public endpoint to retrieve all configurations from senate in one single external call
     *
     * NOTE The function always checks the status of Senator and his Representation Members
     */
    function getSettings()
        public
        view
        virtual
        override
        returns (
            uint256 currProposalThreshold,
            uint256 currVotingDelay,
            uint256 currVotingPeriod,
            bytes memory senatorRepresentations,
            uint256 votingPower,
            bool validSenator,
            bool validMembers
        )
    {
        return _senate.getSettings(msg.sender);
    }

    /**
     * Read the voting weight from the senates's built in snapshot mechanism (see {ChancellorUpgradeable-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return _senate.getVotes(account, blockNumber, _defaultParams());
    }

    /**
     * Validate a list of Members
     */
    function _validateMembers(bytes memory members)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _senate.validateMembers(members);
    }

    /**
     * Validate Senator
     */
    function _validateSenator(address senator)
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _senate.validateSenator(senator);
    }

    /**
     * @dev Private endpoint to update the underlying senate instance.
     * @dev Emits SenateChange event
     *
     * CAUTION: It is not recommended to change the senate while there are active proposals.
     */
    function _updateSenate(SenateUpgradeable newSenate) private {
        emit SenateChange(address(_senate), address(newSenate));
        _senate = newSenate;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
