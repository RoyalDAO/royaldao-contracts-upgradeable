// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Governance/ChancelorUpgradeable.sol";
import "../Governance/extensions/ChancelorSenateControlUpgradeable.sol";
import "../Governance/extensions/ChancelorTimelockControlUpgradeable.sol";
import "../Governance/compatibility/ChancelorCompatibilityBravoUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RepublicChancelor is
    Initializable,
    ChancelorUpgradeable,
    ChancelorCompatibilityBravoUpgradeable,
    ChancelorSenateControlUpgradeable,
    ChancelorTimelockControlUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        TimelockControllerUpgradeable _timelock,
        SenateUpgradeable _senate
    ) public initializer {
        __Chancelor_init("RepublicChancelor");
        __ChancelorCompatibilityBravo_init();
        __ChancelorSenateControl_init(_senate);
        __ChancelorTimelockControl_init(_timelock);
    }

    function votingDelay()
        public
        view
        override(IChancelorUpgradeable, ChancelorSenateControlUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IChancelorUpgradeable, ChancelorSenateControlUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IChancelorUpgradeable, ChancelorSenateControlUpgradeable)
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
        override(ChancelorUpgradeable, ChancelorSenateControlUpgradeable)
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
            ChancelorTimelockControlUpgradeable,
            ChancelorSenateControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
