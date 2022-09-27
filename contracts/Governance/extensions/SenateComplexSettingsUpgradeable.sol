// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.0;

import "../ChancelorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/**
 * @dev Extension of {Chancelor} for settings updatable through governance.
 *
 * _Available since v4.4._
 */
abstract contract SenateComplexSettingsUpgradeable is
    Initializable,
    ChancelorUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ProposalType {
        bytes typeName;
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThreshold;
    }

    event TypeSet(
        uint256 typeId,
        bytes typeName,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 proposalThreshold
    );

    event TypeUpdated(
        uint256 typeId,
        bytes typeName,
        uint256 newVotingDelay,
        uint256 newVotingPeriod,
        uint256 newProposalThreshold
    );

    CountersUpgradeable.Counter private _typeIdCounter;

    mapping(uint256 => ProposalType) private proposalTypes;

    /**
     * @dev Initialize the governance parameters.
     */
    function __ChancelorComplexSettings_init(
        ProposalType[] memory _proposalTypes
    ) internal onlyInitializing {
        __ChancelorComplexSettings_init_unchained(_proposalTypes);
    }

    function __ChancelorComplexSettings_init_unchained(
        ProposalType[] memory _proposalTypes
    ) internal onlyInitializing {
        for (uint256 idx = 0; idx < _proposalTypes.length; idx++) {
            _typeIdCounter.increment();
            proposalTypes[_typeIdCounter.current()] = _proposalTypes[idx];
        }
    }

    /**
     * @dev See {IChancelor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        require(_typeIdCounter.current() > 0, "No Proposal Types created!");
        return 0;
        //return votingDelayOfType(1);
    }

    /**
     * @dev See {IChancelor-votingDelay}.
     */
    /*function votingDelayOfType(uint256 _typeId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            _typeId <= _typeIdCounter.current(),
            "Type with given Id not created yet!"
        );
        return proposalTypes[_typeId].votingDelay;
    }*/

    /**
     * @dev See {IChancelor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        require(_typeIdCounter.current() > 0, "No Proposal Types created!");
        return 0;
        //return votingPeriodOfType(1);
    }

    /**
     * @dev See {IChancelor-votingPeriod}.
     */
    /*function votingPeriodOfType(uint256 _typeId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            _typeId <= _typeIdCounter.current(),
            "Type with given Id not created yet!"
        );
        return proposalTypes[_typeId].votingPeriod;
    }*/

    /**
     * @dev See {Chancelor-proposalThreshold}.
     */
    function proposalThreshold()
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_typeIdCounter.current() > 0, "No Proposal Types created!");
        return proposalTypes[1].proposalThreshold;
    }

    /**
     * @dev See {Chancelor-proposalThreshold}.
     */
    /*function proposalThresholdOfType(uint256 _typeId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            _typeId <= _typeIdCounter.current(),
            "Type with given Id not created yet!"
        );

        return proposalTypes[_typeId].proposalThreshold;
    }*/

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setProposalType(
        bytes memory _typeName,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold
    ) public virtual onlyChancelor {
        _setProposalType(
            _typeName,
            _votingDelay,
            _votingPeriod,
            _proposalThreshold
        );
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setProposalType(
        bytes memory _typeName,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold
    ) internal virtual {
        require(!_typeExists(_typeName), "Duplicated TypeName");

        _typeIdCounter.increment();

        emit TypeSet(
            _typeIdCounter.current(),
            _typeName,
            _votingDelay,
            _votingPeriod,
            _proposalThreshold
        );

        proposalTypes[_typeIdCounter.current()] = ProposalType({
            typeName: _typeName,
            votingDelay: _votingDelay,
            votingPeriod: _votingPeriod,
            proposalThreshold: _proposalThreshold
        });
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function updateProposalType(
        uint256 _typeId,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold
    ) public virtual onlyChancelor {
        _updateProposalType(
            _typeId,
            _votingDelay,
            _votingPeriod,
            _proposalThreshold
        );
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _updateProposalType(
        uint256 _typeId,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold
    ) internal virtual {
        require(
            _typeId <= _typeIdCounter.current(),
            "Type with given Id not created yet!"
        );

        emit TypeUpdated(
            _typeId,
            proposalTypes[_typeIdCounter.current()].typeName,
            _votingDelay,
            _votingPeriod,
            _proposalThreshold
        );

        proposalTypes[_typeIdCounter.current()].votingDelay = _votingDelay;
        proposalTypes[_typeIdCounter.current()].votingPeriod = _votingPeriod;
        proposalTypes[_typeIdCounter.current()]
            .proposalThreshold = _proposalThreshold;
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _typeExists(bytes memory _typeName)
        internal
        virtual
        returns (bool)
    {
        for (uint256 idx = 0; idx < _typeIdCounter.current(); idx++) {
            if (
                keccak256(proposalTypes[idx + 1].typeName) ==
                keccak256(_typeName)
            ) return true;
        }

        return false;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
