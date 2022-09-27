// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "../SenateUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
 *
 * _Available since v4.3._
 *
 * @custom:storage-size 51
 */
abstract contract SenateVotesUpgradeable is Initializable, SenateUpgradeable {
    //TODO: Complex votes for single vote by token
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function __SenateVotes_init() internal onlyInitializing {
        __SenateVotes_init_unchained();
    }

    function __SenateVotes_init_unchained() internal onlyInitializing {}

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Chancelor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        uint256 totalVotes;

        for (uint256 idx = 0; idx < tokens.values().length; idx++) {
            if (
                banned.contains(tokens.values()[idx]) ||
                quarantine[tokens.values()[idx]] >= block.number
            ) continue;

            if (
                IERC165Upgradeable(tokens.values()[idx]).supportsInterface(
                    type(IVotesUpgradeable).interfaceId
                )
            )
                totalVotes += IVotesUpgradeable(tokens.values()[idx])
                    .getPastVotes(account, blockNumber);
        }

        return totalVotes;
    }

    /**
     * Read the total voting suply at last block mined.
     */
    function _getTotalSuply() internal view virtual override returns (uint256) {
        uint256 totalVotes;

        for (uint256 idx = 0; idx < tokens.values().length; idx++) {
            if (
                banned.contains(tokens.values()[idx]) ||
                quarantine[tokens.values()[idx]] >= (block.number - 1)
            ) continue;

            if (
                IERC165Upgradeable(tokens.values()[idx]).supportsInterface(
                    type(IVotesUpgradeable).interfaceId
                )
            )
                totalVotes += IVotesUpgradeable(tokens.values()[idx])
                    .getPastTotalSupply(block.number - 1);
        }

        return totalVotes;
    }

    /**
     * @dev Check if `account` at a specific `blockNumber` reachs the treshold.
     */
    function _checkTresholdReached(
        address account,
        uint256 blockNumber,
        uint256 proposalThreshold
    ) internal view virtual override returns (bool) {
        uint256 totalVotes;

        for (uint256 idx = 0; idx < tokens.values().length; idx++) {
            if (
                banned.contains(tokens.values()[idx]) ||
                quarantine[tokens.values()[idx]] >= block.number
            ) continue;

            if (
                IERC165Upgradeable(tokens.values()[idx]).supportsInterface(
                    type(IVotesUpgradeable).interfaceId
                )
            ) {
                totalVotes += IVotesUpgradeable(tokens.values()[idx])
                    .getPastVotes(account, blockNumber);

                if (totalVotes >= proposalThreshold) return true;
            }
        }

        return false;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
