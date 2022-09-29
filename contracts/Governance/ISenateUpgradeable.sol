// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Interface of the {Senate} core.
 *
 * _Available since v4.3._
 * IChancelorUpgradeable.sol modifies OpenZeppelin's IGovernorUpgradeable.sol:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/governance/IGovernorUpgradeable.sol
 * IGovernorUpgradeable.sol source code copyright OpenZeppelin licensed under the MIT License.
 * Modified by QueenE DAO.
 */
abstract contract ISenateUpgradeable is Initializable, IERC165Upgradeable {
    function __ISenate_init(
        string memory name_,
        address[] memory _tokens,
        address _marshalDeputy,
        uint256 _quarantinePeriod
    ) internal onlyInitializing {}

    function __ISenate_init_unchained(
        string memory name_,
        address[] memory _tokens,
        address _marshalDeputy,
        uint256 _quarantinePeriod
    ) internal onlyInitializing {}

    enum membershipStatus {
        NOT_MEMBER,
        ACTIVE_MEMBER,
        QUARANTINE_MEMBER,
        BANNED_MEMBER
    }

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, or delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @dev Update Senate Voting Books.
     */
    function transferVotingUnits(
        address from,
        address to,
        uint256 amount
    ) external virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
