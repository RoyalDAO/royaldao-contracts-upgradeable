// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../contracts/ChancelorUpgradeable.sol";
import "../../contracts/extensions/ChancelorSettingsUpgradeable.sol";
import "../../contracts/extensions/SenateVotesUpgradeable.sol";
import "../../contracts/extensions/SenateVotesQuorumFractionUpgradeable.sol";
import "../../contracts/extensions/ChancelorTimelockControlUpgradeable.sol";
import "../../contracts/compatibility/ChancelorCompatibilityBravoUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RepublicChancelor is
    Initializable,
    ChancelorUpgradeable,
    ChancelorSettingsUpgradeable,
    ChancelorCompatibilityBravoUpgradeable,
    SenateVotesUpgradeable,
    SenateVotesQuorumFractionUpgradeable,
    ChancelorTimelockControlUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVotesUpgradeable[] memory _tokensUpgradeable,
        IVotes[] memory _tokens,
        TimelockControllerUpgradeable _timelock,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _tokenTreshold,
        uint256 _quorumPercentage
    ) public initializer {
        __Chancelor_init("RepublicChancelor");
        __ChancelorSettings_init(_votingDelay, _votingPeriod, _tokenTreshold);
        __ChancelorCompatibilityBravo_init();
        //__ChancelorCountingSimple_init();
        __SenateVotes_init(_tokensUpgradeable, _tokens);
        __SenateVotesQuorumFraction_init(_quorumPercentage);
        __ChancelorTimelockControl_init(_timelock);
    }

    function votingDelay()
        public
        view
        override(IChancelorUpgradeable, ChancelorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IChancelorUpgradeable, ChancelorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function votingDelayOfType(uint256 _typeId)
        public
        view
        override(IChancelorUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriodOfType(uint256 _typeId)
        public
        view
        override(IChancelorUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IChancelorUpgradeable, SenateVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function quorumReached(uint256 proposalId) public view returns (bool) {
        return super._quorumReached(proposalId);
    }

    function state(uint256 proposalId)
        public
        view
        override(
            ChancelorUpgradeable,
            IChancelorUpgradeable,
            ChancelorTimelockControlUpgradeable
        )
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(
            ChancelorUpgradeable,
            ChancelorCompatibilityBravoUpgradeable,
            IChancelorUpgradeable
        )
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(ChancelorUpgradeable, ChancelorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(ChancelorUpgradeable, ChancelorTimelockControlUpgradeable)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(ChancelorUpgradeable, ChancelorTimelockControlUpgradeable)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(ChancelorUpgradeable, ChancelorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ChancelorUpgradeable,
            IERC165Upgradeable,
            ChancelorTimelockControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
