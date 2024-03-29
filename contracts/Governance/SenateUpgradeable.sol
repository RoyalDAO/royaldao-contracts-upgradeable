// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)
// RoyalDAO Contracts (last updated v1.2.0) (Governance/utils/SenateUpgradeable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/TimersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./ISenateUpgradeable.sol";
import "../Governance/utils/ISenatorVotesUpgradeable.sol";
import "../Utils/ArrayBytesUpgradeable.sol";

/**
 * @dev Contract made to handle multiple tokens as members of the same DAO.
 *
 * _Available since v1.1._
 * Last Updated v1.2.0
 *
 */
abstract contract SenateUpgradeable is
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  EIP712Upgradeable,
  ISenateUpgradeable
{
  //TODO: Complex votes for single vote by token
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using BytesArrayLib32Upgradeable for bytes;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /**
   * @dev storage for members that implements ERC721SenatorVotes
   * @dev ERC721SenatorVotes implementers have function that don't exists in ERC721Votes implementers
   */
  EnumerableSetUpgradeable.AddressSet internal tokens;

  /**
   * @dev storage for members that implements ERC721Votes
   */
  EnumerableSetUpgradeable.AddressSet internal oldDogsTokens;

  /**
   * @dev address of DAO Executor (If uses TimeLock, should be TimeLock address. Chancellor address otherwise).
   */
  address public chancellor;

  /**
   * @dev generator of sequential member ids.
   */
  CountersUpgradeable.Counter internal memberCounter;

  /**
   * @dev mappings to manage translation Member Address <--> Member Id.
   */
  mapping(address => uint32) internal memberId;
  mapping(uint32 => address) internal idMember;

  string private _name;

  /**
   * @dev Modifier to ensure that caller is Chancellor
   */
  modifier onlyChancellor() {
    require(
      msg.sender == chancellor,
      "SenateUpgradeable::Only Chancellor allowed!"
    );
    _;
  }

  /**
   * @dev Modifier to ensure that Senate is Open
   */
  modifier ifSenateOpen() {
    require(
      tokens.length() > 0 || oldDogsTokens.length() > 0,
      "SenateUpgradeable::Senate Not Open!"
    );
    _;
  }

  /**
   * @dev Modifier to ensure that Senate is Closed
   */
  modifier ifSenateClosed() {
    require(
      tokens.length() == 0 && oldDogsTokens.length() == 0,
      "SenateUpgradeable::Senate Already Open!"
    );
    _;
  }

  /**
   * @dev Modifier to ensure that Member is accepted part of the Senate
   */
  modifier onlyValidMember() {
    require(
      senateMemberStatus(msg.sender) == membershipStatus.ACTIVE_MEMBER,
      "SenateUpgradeable::Invalid Senate Member"
    );
    _;
  }

  function __Senate_init(
    string memory name_,
    address _chancellor
  ) internal onlyInitializing {
    __EIP712_init_unchained(name_, version());
    __SenateVotes_init_unchained(_chancellor);
  }

  function __SenateVotes_init_unchained(
    address _chancellor
  ) internal onlyInitializing {
    chancellor = _chancellor;
  }

  /**
   * @dev See {ISenateUpgradeable-openSenate}.
   */
  function openSenate(
    address[] memory _tokens
  ) public virtual override ifSenateClosed {
    for (uint256 idx = 0; idx < _tokens.length; idx++) {
      if (
        IERC165Upgradeable(_tokens[idx]).supportsInterface(
          type(ISenatorVotesUpgradeable).interfaceId
        )
      ) {
        if (!tokens.contains(_tokens[idx])) {
          memberCounter.increment();
          memberId[_tokens[idx]] = SafeCastUpgradeable.toUint32(
            memberCounter.current()
          );
          idMember[
            SafeCastUpgradeable.toUint32(memberCounter.current())
          ] = _tokens[idx];

          tokens.add(_tokens[idx]);
        }
      } else if (
        IERC165Upgradeable(_tokens[idx]).supportsInterface(
          type(IVotes).interfaceId
        )
      ) {
        if (!oldDogsTokens.contains(_tokens[idx])) {
          memberCounter.increment();
          memberId[_tokens[idx]] = SafeCastUpgradeable.toUint32(
            memberCounter.current()
          );
          idMember[
            SafeCastUpgradeable.toUint32(memberCounter.current())
          ] = _tokens[idx];

          oldDogsTokens.add(_tokens[idx]);
        }
      } else revert("SenateUpgradeable::Invalid implementation!");
    }
  }

  /**
   * @dev Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params` from senate books.
   */
  function getVotes(
    address account,
    uint256 blockNumber,
    bytes memory params
  ) external view virtual returns (uint256) {
    return _getVotes(account, blockNumber, params);
  }

  /**
   * @dev Get the total voting supply from senate books at latest `blockNumber`.
   */
  function getTotalSuply() external view virtual returns (uint256) {
    return _getTotalSuply();
  }

  /**
   * @dev See {ISenate-transferVotingUnits}.
   */
  function transferVotingUnits(
    address from,
    address to,
    uint256 amount,
    bool isSenator,
    bool updateTotalSupply
  ) external virtual override onlyValidMember {
    _transferVotingUnits(
      msg.sender,
      from,
      to,
      amount,
      isSenator,
      updateTotalSupply
    );
  }

  /**
   * @dev See {ISenate-getRepresentation}.
   */
  function getRepresentation(
    address account
  ) external view virtual override returns (bytes memory) {
    return _getRepresentation(account);
  }

  /**
   * @dev Get the current senator representation readable list
   */
  function getRepresentationList(
    address account
  ) external view virtual returns (uint32[] memory) {
    return _getRepresentation(account).getArray();
  }

  /**
   * @dev Accept new Member to Senate from approved proposal
   */
  function acceptToSenate(address _token) external virtual onlyChancellor {
    _acceptToSenate(_token);
  }

  function getNewGang() external view returns (address[] memory) {
    return tokens.values();
  }

  /**
   * @dev Get the current IVotes Implementers Member List
   */
  function getOldDogs() external view returns (address[] memory) {
    return oldDogsTokens.values();
  }

  /**
   * @dev Get the Member Id for given Member address
   */
  function getMemberId(address member) external view returns (uint32) {
    return memberId[member];
  }

  /**
   * @dev Get the Member address with given Id
   */
  function getMemberOfId(uint32 _memberId) external view returns (address) {
    return idMember[_memberId];
  }

  /**
   * @dev {ISenate-validateMembers}.
   */
  function validateMembers(
    bytes memory members
  ) external view virtual override returns (bool) {
    return _validateMembers(members);
  }

  /**
   * @dev {ISenate-validateSenator}.
   */
  function validateSenator(
    address senator
  ) external view virtual override returns (bool) {
    return _validateSenator(senator);
  }

  /**
   * @dev Return current Senate Settings. Must implement it if not using SenateSettings Extension.
   */
  function getSettings(
    address account
  )
    external
    view
    virtual
    returns (
      uint256 proposalThreshold,
      uint256 votingDelay,
      uint256 votingPeriod,
      bytes memory senatorRepresentations,
      uint256 votingPower,
      bool validSenator,
      bool validMembers
    );

  /**
   * @dev See {ISenate-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {ISenate-version}.
   */
  function version() public view virtual override returns (string memory) {
    return "1";
  }

  /**
   * @dev Part of the Chancellor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
   */
  function proposalThreshold() public view virtual returns (uint256) {
    return 0;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(IERC165Upgradeable, ERC165Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(ISenateUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev {ISenate-senateMemberStatus}.
   */
  function senateMemberStatus(
    address _tokenAddress
  ) public view virtual override returns (membershipStatus);

  /**
   * @dev {ISenate-senatorStatus}.
   */
  function senatorStatus(
    address _senator
  ) public view virtual override returns (senateSenatorStatus);

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
  function getPastTotalSupply(
    uint256 blockNumber
  ) public view virtual returns (uint256);

  /**
   * @dev internal function to process new member entrance
   */
  function _acceptToSenate(address _token) internal {
    //require(!banned.contains(_token), "Senate::Banned are Exiled");
    require(
      senateMemberStatus(_token) != membershipStatus.BANNED_MEMBER,
      "Senate::Banned are Exiled"
    );

    if (
      IERC165Upgradeable(_token).supportsInterface(
        type(ISenatorVotesUpgradeable).interfaceId
      )
    ) {
      if (!tokens.contains(_token)) {
        memberCounter.increment();
        memberId[_token] = SafeCastUpgradeable.toUint32(
          memberCounter.current()
        );
        idMember[
          SafeCastUpgradeable.toUint32(memberCounter.current())
        ] = _token;

        //must sync senate books
        writeMemberToSenateBooks(_token);
        //set senate to new member
        try ISenatorVotesUpgradeable(_token).setSenate(this) {} catch {}
        //add New Member to Senate List of Members
        tokens.add(_token);
      }
    } else if (
      IERC165Upgradeable(_token).supportsInterface(type(IVotes).interfaceId)
    ) {
      if (!oldDogsTokens.contains(_token)) {
        memberCounter.increment();
        memberId[_token] = SafeCastUpgradeable.toUint32(
          memberCounter.current()
        );
        idMember[
          SafeCastUpgradeable.toUint32(memberCounter.current())
        ] = _token;

        oldDogsTokens.add(_token);
      }
    } else revert("SenateUpgradeable::Invalid implementation!");

    //emit event
    emit MemberAcceptance(_token, msg.sender);
  }

  /**
   * @dev Return a list of quarantined and banned members
   */
  function getInaptMembers() public view virtual returns (address[] memory) {
    return _getInaptMembers();
  }

  /**
   * @dev Return a list of quarantined and banned members
   */
  function _getInaptMembers() internal view virtual returns (address[] memory);

  /**
   * @dev Check if all members from list are valid.
   */
  function _validateMembers(
    bytes memory members
  ) internal view virtual returns (bool);

  /**
   * @dev Check if a given member is valid.
   */
  function _validateMember(uint32 member) internal view virtual returns (bool);

  /**
   * @dev Check if senator is active.
   */
  function _validateSenator(
    address senator
  ) internal view virtual returns (bool);

  /**
   * @dev Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params`.
   * @dev Overriden by SenateVotes extension.
   * @dev If not using SenateVotes extension, must implement.
   */
  function _getVotes(
    address account,
    uint256 blockNumber,
    bytes memory params
  ) internal view virtual returns (uint256);

  /**
   * @dev Get total voting suply until last block.
   * @dev Overriden by SenateVotes extension.
   * @dev If not using SenateVotes extension, must implement.
   */
  function _getTotalSuply() internal view virtual returns (uint256);

  /**
   * @dev Get the Senator Representations
   * @dev Representation is a list of the Members(tokens) from whom the Senator owns 1 or more tokens
   */
  function _getRepresentation(
    address account
  ) internal view virtual returns (bytes memory);

  /**
   * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
   * should be zero. Total supply of voting units will be adjusted with mints and burns.
   * @dev Overriden by SenateVotes extension.
   * @dev If not using SenateVotes extension, must implement.
   */
  function _transferVotingUnits(
    address member,
    address from,
    address to,
    uint256 amount,
    bool isSenator,
    bool updateTotalSupply
  ) internal virtual;

  /**
   * @dev Burn suply of given member that was banished or quarantined
   */
  function _burnMemberVotings(address member) internal virtual;

  /**
   * @dev Burn suply of given senator that was banished or quarantined
   */
  function _burnSenatorVotings(address _senator) internal virtual;

  /**
   * @dev Recover suply of given senator that is getting out of quarantine
   */
  function _restoreSenatorVotings(address _senator) internal virtual;

  /**
   * @dev Recover suply of given member that is getting out of quarantine
   */
  function _restoreMemberVotings(address _token) internal virtual;

  /**
   *@dev writes the voting distribution of a Member that enters the senate after its opening
   *
   *NOTE: this function only works for SenatorVotes implementers
   */
  function writeMemberToSenateBooks(address member) private {
    //get owners list
    ISenatorVotesUpgradeable.senateSnapshot[]
      memory _totalSuply = ISenatorVotesUpgradeable(member).getSenateSnapshot();

    for (uint256 idx = 0; idx < _totalSuply.length; idx++) {
      _transferVotingUnits(
        member,
        address(0),
        _totalSuply[idx].senator,
        _totalSuply[idx].votes,
        true,
        true
      );
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[42] private __gap;
}
