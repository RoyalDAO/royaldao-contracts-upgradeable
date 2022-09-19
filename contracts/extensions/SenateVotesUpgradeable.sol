// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "../ChancelorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
 *
 * _Available since v4.3._
 *
 * @custom:storage-size 51
 */
abstract contract SenateVotesUpgradeable is
    Initializable,
    ChancelorUpgradeable
{
    //TODO: Quarantine from senate
    //TODO: Ban from senate
    //TODO: Complex votes for single vote by token
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet internal tokens;
    EnumerableSetUpgradeable.AddressSet internal tokensUpgradeable;

    //IVotesUpgradeable public token;

    function __SenateVotes_init(
        IVotesUpgradeable[] memory _upgradeableTokens,
        IVotes[] memory _tokens
    ) internal onlyInitializing {
        __SenateVotes_init_unchained(_upgradeableTokens, _tokens);
    }

    function __SenateVotes_init_unchained(
        IVotesUpgradeable[] memory _upgradeableTokens,
        IVotes[] memory _tokens
    ) internal onlyInitializing {
        for (uint256 idx = 0; idx < _upgradeableTokens.length; idx++) {
            tokensUpgradeable.add(address(_upgradeableTokens[idx]));
        }
        for (uint256 idx = 0; idx < _tokens.length; idx++) {
            tokensUpgradeable.add(address(_tokens[idx]));
        }
        //token = tokenAddress;
    }

    function acceptToSenate(IVotesUpgradeable _upgradeableToken, IVotes _token)
        internal
        onlyChancelor
    {
        if (!tokens.contains(address(_token)) && address(_token) != address(0))
            tokens.add(address(_token));

        if (
            !tokensUpgradeable.contains(address(_upgradeableToken)) &&
            address(_upgradeableToken) != address(0)
        ) tokensUpgradeable.add(address(_upgradeableToken));
    }

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
            totalVotes += IVotes(tokens.values()[idx]).getPastVotes(
                account,
                blockNumber
            );
        }
        for (uint256 idx = 0; idx < tokensUpgradeable.values().length; idx++) {
            totalVotes += IVotesUpgradeable(tokensUpgradeable.values()[idx])
                .getPastVotes(account, blockNumber);
        }

        return totalVotes;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
