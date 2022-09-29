// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import "../SenateUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CheckpointsUpgradeable.sol";
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

    using CheckpointsUpgradeable for CheckpointsUpgradeable.History;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => CheckpointsUpgradeable.History)
        private _delegateCheckpoints;
    CheckpointsUpgradeable.History private _totalCheckpoints;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event SenateBooksDelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event SenateBooksDelegateVotesChanged(
        address indexed senateMember,
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Chancelor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        uint256 totalVotes;

        totalVotes += _delegateCheckpoints[account].getAtProbablyRecentBlock(
            blockNumber
        );
        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            if (
                banned.contains(tokens.values()[idx]) ||
                quarantine[tokens.values()[idx]] >= (block.number - 1)
            ) continue;

            totalVotes += IVotesUpgradeable(oldDogsTokens.values()[idx])
                .getPastVotes(account, block.number - 1);
        }

        return totalVotes;
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber)
        public
        view
        virtual
        returns (uint256)
    {
        return
            _delegateCheckpoints[account].getAtProbablyRecentBlock(blockNumber);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(blockNumber < block.number, "Votes: block not yet mined");

        uint256 _totalSuply;

        _totalSuply += _totalCheckpoints.getAtProbablyRecentBlock(blockNumber);

        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            if (
                banned.contains(oldDogsTokens.values()[idx]) ||
                quarantine[oldDogsTokens.values()[idx]] >= (block.number - 1)
            ) continue;
            _totalSuply += IVotesUpgradeable(oldDogsTokens.values()[idx])
                .getPastTotalSupply(blockNumber);
        }

        return _totalSuply;
    }

    /**
     * Read the total voting suply at last block mined.
     */
    function _getTotalSuply() internal view virtual override returns (uint256) {
        uint256 _totalSuply;

        _totalSuply += _totalCheckpoints.latest();

        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            if (
                banned.contains(oldDogsTokens.values()[idx]) ||
                quarantine[oldDogsTokens.values()[idx]] >= (block.number - 1)
            ) continue;

            _totalSuply += IVotesUpgradeable(oldDogsTokens.values()[idx])
                .getPastTotalSupply(block.number - 1);
        }

        return _totalSuply;
    }

    //book functions
    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    function _transferVotingUnits(
        address member,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == address(0)) {
            _totalCheckpoints.push(_add, amount);
        }
        if (to == address(0)) {
            _totalCheckpoints.push(_subtract, amount);
        }
        _moveDelegateVotes(member, from, to, amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(
        address member,
        address from,
        address to,
        uint256 amount
    ) private {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[
                    from
                ].push(_subtract, amount);

                emit SenateBooksDelegateVotesChanged(
                    member,
                    from,
                    oldValue,
                    newValue
                );
            }
            if (to != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[to]
                    .push(_add, amount);

                emit SenateBooksDelegateVotesChanged(
                    member,
                    to,
                    oldValue,
                    newValue
                );
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner)
        internal
        virtual
        returns (uint256 current)
    {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Returns an address nonce.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
