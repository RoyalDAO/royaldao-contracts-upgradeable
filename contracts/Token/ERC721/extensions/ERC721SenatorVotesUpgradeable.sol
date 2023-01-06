// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/extensions/draft-ERC721Votes.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../../../Governance/utils/SenatorVotesUpgradeable.sol";
import "../../../Governance/utils/ISenatorVotesUpgradeable.sol";
import "../../../Governance/ISenateUpgradeable.sol";

/**
 * @dev Extension of Openzeppelin's {ERC721Upgradeable} to support voting and delegation as implemented by {SenatorVotesUpgradeable}, where each individual NFT counts
 * as 1 vote unit.
 *
 * ERC721SenatorVotes.sol modifies OpenZeppelin's ERC721Votes.sol:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC721/extensions/ERC721VotesUpgradeable.sol
 * ERC721VotesUpgradeable.sol source code copyright OpenZeppelin licensed under the MIT License.
 * Modified by RoyalDAO.
 *
 * CHANGES: - Adapted to work with the {SenateUpgradeable}, informing support of {ISenatorVotesUpgradeable} interface so the senate can recognize 
              the token voting control implementation type.
            - Inheritage of SenatorVotes pattern
            
 * _Available since v1.0._
 */
abstract contract ERC721SenatorVotesUpgradeable is
    Initializable,
    ERC721Upgradeable,
    SenatorVotesUpgradeable
{
    function __ERC721SenatorVotes_init(ISenateUpgradeable _senate)
        internal
        onlyInitializing
    {
        __ERC721SenatorVotes_init_unchained(_senate);
    }

    function __ERC721SenatorVotes_init_unchained(ISenateUpgradeable _senate)
        internal
        onlyInitializing
    {
        __Votes_init(_senate);
    }

    /**
     * @dev Adjusts votes when tokens are transferred.
     *
     * Emits a {Votes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _transferVotingUnits(from, to, 1);

        super._afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Returns the balance of `account`.
     */
    function _getVotingUnits(address account)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return balanceOf(account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(ISenatorVotesUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
