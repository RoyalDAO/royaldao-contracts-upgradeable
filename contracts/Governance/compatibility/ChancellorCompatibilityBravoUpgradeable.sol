// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.0.0) (Governance/extensions/ChancelorCompatibilityBravoUpgradeable.sol)
// Uses OpenZeppelin Contracts and Libraries

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IChancellorCompatibilityBravoUpgradeable.sol";
import "../extensions/IChancellorTimelockUpgradeable.sol";
import "../ChancellorUpgradeable.sol";

/**
 
 * @dev Compatibility layer that implements GovernorBravo compatibility on to of {Chancelor}.
 *
 * This compatibility layer includes a voting system and requires a {IChancelorTimelockUpgradeable} compatible module to be added
 * through inheritance. It does not include token bindings, not does it include any variable upgrade patterns.
 *
 * ChancelorCompatibilityBravoUpgradeable.sol modifies OpenZeppelin's GovernorCompatibilityBravoUpgradeable.sol:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/governance/compatibility/GovernorCompatibilityBravoUpgradeable.sol
 * GovernorCompatibilityBravoUpgradeable.sol source code copyright OpenZeppelin licensed under the MIT License.
 * Modified by RoyalDAO.
 *
 * NOTE: When using this module, you may need to enable the Solidity optimizer to avoid hitting the contract size limit.
 *
 * _Available since v1.0._
 */
abstract contract ChancellorCompatibilityBravoUpgradeable is
    Initializable,
    IChancellorTimelockUpgradeable,
    IChancellorCompatibilityBravoUpgradeable,
    ChancellorUpgradeable
{
    function __ChancellorCompatibilityBravo_init() internal onlyInitializing {}

    function __ChancellorCompatibilityBravo_init_unchained()
        internal
        onlyInitializing
    {}

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalDetails {
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => Receipt) receipts;
        bytes32 descriptionHash;
    }

    mapping(uint256 => ProposalDetails) private _proposalDetails;

    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE()
        public
        pure
        virtual
        override
        returns (string memory)
    {
        return "support=bravo&quorum=bravo";
    }

    // ============================================== Proposal lifecycle ==============================================
    /**
     * @dev See {IChancellorUpgradeable-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        virtual
        override(IChancellorUpgradeable, ChancellorUpgradeable)
        returns (uint256)
    {
        _storeProposal(
            _msgSender(),
            targets,
            values,
            new string[](calldatas.length),
            calldatas,
            description
        );
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @dev See {IChancellorCompatibilityBravoUpgradeable-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        _storeProposal(
            _msgSender(),
            targets,
            values,
            signatures,
            calldatas,
            description
        );
        return
            propose(
                targets,
                values,
                _encodeCalldata(signatures, calldatas),
                description
            );
    }

    /**
     * @dev See {IChancellorCompatibilityBravoUpgradeable-queue}.
     */
    function queue(uint256 proposalId) public virtual override {
        ProposalDetails storage details = _proposalDetails[proposalId];
        queue(
            details.targets,
            details.values,
            _encodeCalldata(details.signatures, details.calldatas),
            details.descriptionHash
        );
    }

    /**
     * @dev See {IChancellorCompatibilityBravoUpgradeable-execute}.
     */
    function execute(uint256 proposalId) public payable virtual override {
        ProposalDetails storage details = _proposalDetails[proposalId];
        execute(
            details.targets,
            details.values,
            _encodeCalldata(details.signatures, details.calldatas),
            details.descriptionHash
        );
    }

    function cancel(uint256 proposalId) public virtual override {
        ProposalDetails storage details = _proposalDetails[proposalId];

        require(
            _msgSender() == details.proposer ||
                getVotes(details.proposer, block.number - 1) <
                proposalThreshold(),
            "GovernorBravo: proposer above threshold"
        );

        _cancel(
            details.targets,
            details.values,
            _encodeCalldata(details.signatures, details.calldatas),
            details.descriptionHash
        );
    }

    /**
     * @dev Encodes calldatas with optional function signature.
     */
    function _encodeCalldata(
        string[] memory signatures,
        bytes[] memory calldatas
    ) private pure returns (bytes[] memory) {
        bytes[] memory fullcalldatas = new bytes[](calldatas.length);

        for (uint256 i = 0; i < signatures.length; ++i) {
            fullcalldatas[i] = bytes(signatures[i]).length == 0
                ? calldatas[i]
                : abi.encodePacked(
                    bytes4(keccak256(bytes(signatures[i]))),
                    calldatas[i]
                );
        }

        return fullcalldatas;
    }

    /**
     * @dev Store proposal metadata for later lookup
     */
    function _storeProposal(
        address proposer,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) private {
        bytes32 descriptionHash = keccak256(bytes(description));
        uint256 proposalId = hashProposal(
            targets,
            values,
            _encodeCalldata(signatures, calldatas),
            descriptionHash
        );

        ProposalDetails storage details = _proposalDetails[proposalId];
        if (details.descriptionHash == bytes32(0)) {
            details.proposer = proposer;
            details.targets = targets;
            details.values = values;
            details.signatures = signatures;
            details.calldatas = calldatas;
            details.descriptionHash = descriptionHash;
        }
    }

    // ==================================================== Views =====================================================
    /**
     * @dev See {IChancellorCompatibilityBravoUpgradeable-proposals}.
     */
    function proposals(uint256 proposalId)
        public
        view
        virtual
        override
        returns (
            uint256 id,
            address proposer,
            uint256 eta,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool canceled,
            bool executed
        )
    {
        id = proposalId;
        eta = proposalEta(proposalId);
        startBlock = proposalSnapshot(proposalId);
        endBlock = proposalDeadline(proposalId);

        ProposalDetails storage details = _proposalDetails[proposalId];
        proposer = details.proposer;
        forVotes = details.forVotes;
        againstVotes = details.againstVotes;
        abstainVotes = details.abstainVotes;

        ProposalState status = state(proposalId);
        canceled = status == ProposalState.Canceled;
        executed = status == ProposalState.Executed;
    }

    /**
     * @dev See {IChancellorCompatibilityBravoUpgradeable-getActions}.
     */
    function getActions(uint256 proposalId)
        public
        view
        virtual
        override
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        ProposalDetails storage details = _proposalDetails[proposalId];
        return (
            details.targets,
            details.values,
            details.signatures,
            details.calldatas
        );
    }

    /**
     * @dev See {IChancellorCompatibilityBravoUpgradeable-getReceipt}.
     */
    function getReceipt(uint256 proposalId, address voter)
        public
        view
        virtual
        override
        returns (Receipt memory)
    {
        return _proposalDetails[proposalId].receipts[voter];
    }

    /**
     * @dev See {IChancellorCompatibilityBravoUpgradeable-quorumVotes}.
     */
    function quorumVotes() public view virtual override returns (uint256) {
        return quorum(block.number - 1);
    }

    // ==================================================== Voting ====================================================
    /**
     * @dev See {IChancellorUpgradeable-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _proposalDetails[proposalId].receipts[account].hasVoted;
    }

    /**
     * @dev See {ChancellorUpgradeable-_quorumReached}. In this module, only forVotes count toward the quorum.
     */
    function _quorumReached(uint256 proposalId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        ProposalDetails storage details = _proposalDetails[proposalId];
        return quorum(proposalSnapshot(proposalId)) <= details.forVotes;
    }

    /**
     * @dev See {ChancellorUpgradeable-_voteSucceeded}. In this module, the forVotes must be scritly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        ProposalDetails storage details = _proposalDetails[proposalId];
        return details.forVotes > details.againstVotes;
    }

    /**
     * @dev See {ChancellorUpgradeable-_countVote}. In this module, the support follows Governor Bravo.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalDetails storage details = _proposalDetails[proposalId];
        Receipt storage receipt = details.receipts[account];

        require(
            !receipt.hasVoted,
            "ChancellorCompatibilityBravoUpgradeable: vote already cast"
        );
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = SafeCastUpgradeable.toUint96(weight);

        if (support == uint8(VoteType.Against)) {
            details.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            details.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            details.abstainVotes += weight;
        } else {
            revert(
                "ChancellorCompatibilityBravoUpgradeable: invalid vote type"
            );
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
