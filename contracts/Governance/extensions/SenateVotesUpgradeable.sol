// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.0.0) (Governance/extensions/SenateVotesUpgradeable.sol)
// Uses OpenZeppelin Contracts and Libraries

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "../SenateUpgradeable.sol";
import "../../Governance/utils/ISenatorVotesUpgradeable.sol";
import "../../Utils/CheckpointsUpgradeable.sol";
import "../../Utils/ArrayBytesUpgradeable.sol";

/**
 * @dev Extension of {SenateUpgradeable} for voting weight extraction from an {ERC721SenatorVotesUpgradeable/ERC721VotesUpgradeable} token member of the Senate.
 *
 * @custom:storage-size 51
 */
abstract contract SenateVotesUpgradeable is Initializable, SenateUpgradeable {
    //TODO: Complex votes for single vote by token
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using CheckpointsUpgradeable for CheckpointsUpgradeable.History;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using BytesArrayLib32Upgradeable for bytes;

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /**
     * @dev Senate Books. Keeps senator voting power for SenatorVotes Implementers
     */
    mapping(address => CheckpointsUpgradeable.History)
        internal _senateBooksCheckpoints;
    /**
     * @dev Senate Books. Keeps total voting power for SenatorVotes Implementers
     */
    CheckpointsUpgradeable.History internal _totalSenateBooksCheckpoints;

    //senator representations
    mapping(address => bytes) internal _senatorRepresentationsBytes;

    mapping(address => CountersUpgradeable.Counter) internal _nonces;

    function __SenateVotes_init() internal onlyInitializing {
        __SenateVotes_init_unchained();
    }

    function __SenateVotes_init_unchained() internal onlyInitializing {}

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
     * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
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
        if (!_validateSenator(account)) return 0;

        uint256 totalVotes;

        totalVotes += _senateBooksCheckpoints[account].getAtProbablyRecentBlock(
                blockNumber
            );

        if (oldDogsTokens.length() <= 0) return totalVotes;

        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            if (!_validateMember(memberId[oldDogsTokens.values()[idx]]))
                continue;

            totalVotes += IVotes(oldDogsTokens.values()[idx]).getPastVotes(
                account,
                block.number - 1
            );
        }

        return totalVotes;
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
        require(
            blockNumber < block.number,
            "SenateVotesUpgradeable: block not yet mined"
        );

        uint256 _totalSuply;

        _totalSuply += _totalSenateBooksCheckpoints.getAtProbablyRecentBlock(
            blockNumber
        );

        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            if (!_validateMember(memberId[oldDogsTokens.at(idx)])) continue;
            _totalSuply += IVotes(oldDogsTokens.values()[idx])
                .getPastTotalSupply(blockNumber);
        }

        return _totalSuply;
    }

    /**
     * @dev Returns an address nonce.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     *
     * NOTE Total supply is manipulated only if `updateTotalSupply` is true and Senator and Member are valid
     *      The SenateSecurity extension burns votes from totalSupply if Member or Senator is quarantined/banned
     *      If not using SenateSecurity extension but controls member/senator access, make sure to control supply accordingly
     *
     */
    function _transferVotingUnits(
        address member,
        address from,
        address to,
        uint256 amount,
        bool isSenator,
        bool updateTotalSupply
    ) internal virtual override {
        if (updateTotalSupply) {
            if (
                from == address(0) &&
                _validateSenator(from) &&
                _validateMember(memberId[member])
            ) {
                _totalSenateBooksCheckpoints.push(_add, amount);
            }
            if (
                to == address(0) &&
                _validateSenator(to) &&
                _validateMember(memberId[member])
            ) {
                _totalSenateBooksCheckpoints.push(_subtract, amount);
            }
        }
        _moveDelegateVotes(member, from, to, amount, isSenator);
    }

    /**
     * @dev Burn suply of given member that was banished or quarantined
     */
    function _burnMemberVotings(address member) internal virtual override {
        require(
            !_validateMember(memberId[member]),
            "SenateVotesUpgradeable::Member not banned nor quarantined"
        );

        if (tokens.contains(member))
            _totalSenateBooksCheckpoints.push(
                _subtract,
                ISenatorVotesUpgradeable(member).getTotalSupply()
            );
    }

    /**
     * @dev Burn suply of given senator that was banished or quarantined
     */
    function _burnSenatorVotings(address _senator) internal virtual override {
        require(
            !_validateSenator(_senator),
            "SenateVotesUpgradeable::Senator not banned nor quarantined"
        );

        //burn senator votes for the time being
        uint256 senatorVotes = _senateBooksCheckpoints[_senator]
            .getAtProbablyRecentBlock(block.number - 1);

        if (senatorVotes > 0) {
            //burn senator votes
            _transferVotingUnits(
                address(0),
                _senator,
                address(0),
                senatorVotes,
                false,
                true
            );
        }
    }

    /**
     * @dev Recover suply of given senator that is getting out of quarantine
     */
    function _restoreSenatorVotings(address _senator)
        internal
        virtual
        override
    {
        require(
            senatorStatus(_senator) != senateSenatorStatus.BANNED_SENATOR,
            "SenateVotesUpgradeable::Senator banned"
        );

        require(
            senatorStatus(_senator) == senateSenatorStatus.QUARANTINE_SENATOR,
            "SenateVotesUpgradeable::Senator not in quarantine"
        );

        for (uint256 idx = 0; idx < tokens.length(); idx++) {
            uint256 senatorVotes = ISenatorVotesUpgradeable(tokens.at(idx))
                .getPastVotes(_senator, block.number - 1);

            if (senatorVotes > 0)
                _transferVotingUnits(
                    tokens.at(idx),
                    address(0),
                    _senator,
                    senatorVotes,
                    true,
                    true
                );
        }
    }

    /**
     * @dev Recover suply of given member that is getting out of quarantine
     */
    function _restoreMemberVotings(address _token) internal virtual override {
        require(
            senateMemberStatus(_token) != membershipStatus.BANNED_MEMBER,
            "SenateVotesUpgradeable::Senator banned"
        );

        require(
            senateMemberStatus(_token) == membershipStatus.QUARANTINE_MEMBER,
            "SenateVotesUpgradeable::Member not in quarantine"
        );

        //get senator out of quarantine
        //memberInQuarantine.remove(_token);

        uint256 memberVotes = ISenatorVotesUpgradeable(_token).getTotalSupply();

        if (memberVotes > 0)
            _totalSenateBooksCheckpoints.push(_add, memberVotes);
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
     * @dev Read the voting weight from the senate's built in snapshot mechanism.
     *
     * NOTE For members that dont implement the SenatorVotes, make a external call to get the voting weight.
     *      Invalid Senators always gets zero voting weigth
     *      Invalid Members that dont implement SenatorVotes wont be called and, therefore, gives zero voting weigth
     *
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        if (!_validateSenator(account)) return 0;

        uint256 totalVotes;

        totalVotes += _senateBooksCheckpoints[account].getAtProbablyRecentBlock(
                blockNumber
            );

        if (oldDogsTokens.length() <= 0) return totalVotes;

        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            if (!_validateMember(memberId[oldDogsTokens.values()[idx]]))
                continue;

            totalVotes += IVotes(oldDogsTokens.values()[idx]).getPastVotes(
                account,
                block.number - 1
            );
        }

        return totalVotes;
    }

    /**
     *@dev Read the total voting suply at last block mined.
     *
     * NOTE Invalid Members that dont implement SenatorVotes wont be called and, therefore, gives zero voting weigth to the total supply
     */
    function _getTotalSuply() internal view virtual override returns (uint256) {
        uint256 _totalSuply;

        _totalSuply += _totalSenateBooksCheckpoints.latest();

        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            if (!_validateMember(memberId[oldDogsTokens.at(idx)])) continue;

            _totalSuply += IVotes(oldDogsTokens.values()[idx])
                .getPastTotalSupply(block.number - 1);
        }

        return _totalSuply;
    }

    /**
     * @dev Read the senator representations at the latest block
     * NOTE For members that dont implement the SenatorVotes, make a external call to check if senator owns token from the member.
     *      Invalid Senators represents none.
     */
    function _getRepresentation(address account)
        internal
        view
        virtual
        override
        returns (bytes memory)
    {
        bytes memory representationBytes;
        if (!_validateSenator(account)) return representationBytes;

        representationBytes = _senatorRepresentationsBytes[account];

        if (oldDogsTokens.length() == 0) {
            return representationBytes;
        }

        //call the old dogs
        for (uint256 idx = 0; idx < oldDogsTokens.values().length; idx++) {
            //even if member is invalid, counts representation to protect senate from senator holders
            if (
                IVotes(oldDogsTokens.values()[idx]).getPastVotes(
                    account,
                    block.number - 1
                ) > 0
            )
                representationBytes = representationBytes.insert(
                    memberId[oldDogsTokens.values()[idx]]
                );
        }

        return representationBytes;
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     *
     * NOTE Invalid members dont give nor receive voting power
     */
    function _moveDelegateVotes(
        address member,
        address from,
        address to,
        uint256 amount,
        bool isSenator
    ) private {
        if (from != to && amount > 0) {
            uint32 _memberId = memberId[member];

            if (from != address(0) && _validateSenator(from)) {
                (uint256 oldValue, uint256 newValue) = _senateBooksCheckpoints[
                    from
                ].push(_subtract, amount);

                if (!isSenator) {
                    _senatorRepresentationsBytes[
                        from
                    ] = _senatorRepresentationsBytes[from].remove(_memberId);
                }

                emit SenateBooksDelegateVotesChanged(
                    member,
                    from,
                    oldValue,
                    newValue
                );
            }
            if (to != address(0) && _validateSenator(to)) {
                (uint256 oldValue, uint256 newValue) = _senateBooksCheckpoints[
                    to
                ].push(_add, amount);

                _senatorRepresentationsBytes[to].insertStorage(_memberId);

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}
