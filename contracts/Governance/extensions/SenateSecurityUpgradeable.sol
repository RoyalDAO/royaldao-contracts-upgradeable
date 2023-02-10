// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.2.0) (Governance/extensions/SenateSecurityUpgradeable.sol)
// Uses OpenZeppelin Contracts and Libraries

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../Utils/ArrayBytesUpgradeable.sol";
import "../SenateUpgradeable.sol";

/**
 * @dev Extension of {SenateUpgradeable} for voting control Members and Senator access to the Senate.
 *
 * _Available since v1._
 */
//TODO: Create Veto Option
abstract contract SenateSecurityUpgradeable is
  SenateUpgradeable,
  ReentrancyGuardUpgradeable
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using BytesArrayLib32Upgradeable for bytes;

  /**
   * @dev Emitted when a Senate Member is put under Quarantine
   */
  event MemberQuarantined(address member);
  /**
   * @dev Emitted when a Senator is put under Quarantine
   */
  event SenatorQuarantined(address senator);

  /**
   * @dev Emitted when a Senate Member is released from Quarantine
   */
  event MemberUnquarantined(address member);
  /**
   * @dev Emitted when a Senator is released from Quarantine
   */
  event SenatorUnquarantined(address senator);

  /**
   * @dev Emitted when a Senate Member is Banned
   */
  event MemberBanned(address member);
  /**
   * @dev Emitted when a Senator is Banned
   */
  event SenatorBanned(address senator);

  /**
   * @dev List of banned Members
   */
  EnumerableSetUpgradeable.AddressSet internal banned;
  /**
   * @dev List of banned Senators
   */
  EnumerableSetUpgradeable.AddressSet internal senatorBanned;

  /**
   * @dev List of quarantined members
   */
  EnumerableSetUpgradeable.AddressSet internal memberInQuarantine;
  /**
   * @dev List of quarantined senators
   */
  EnumerableSetUpgradeable.AddressSet internal senatorInQuarantine;

  /**
   * @dev Latest quarantine expiration block for senate members
   */
  mapping(address => uint256) internal memberQuarantine;
  /**
   * @dev Latest quarantine expiration block for senator
   */
  mapping(address => uint256) internal senatorQuarantine;

  /**
   * @dev Quarantine period
   */
  uint256 public quarantinePeriod;

  /**
   * @dev Set the senate.
   */
  function __SenateSecurity_init(
    uint256 _quarantinePeriod
  ) internal onlyInitializing {
    __SenateSecurity_init_unchained(_quarantinePeriod);
  }

  function __SenateSecurity_init_unchained(
    uint256 _quarantinePeriod
  ) internal onlyInitializing {
    //set deputy mandate
    quarantinePeriod = _quarantinePeriod;
  }

  /**
   * @dev Quarantine member from senate
   */
  function quarantineFromSenate(
    address _token
  ) external virtual onlyChancellor nonReentrant {
    _quarantineFromSenate(_token);
  }

  /**
   * @dev Exposed function for Unquarantine member from senate
   *
   * NOTE This function must be implemented in the final contract with access control
   *
   */
  function unquarantineFromSenate(address _token) external virtual {
    _unquarantineFromSenate(_token);
  }

  /**
   * @dev Quarantine Senator from senate
   */
  function quarantineSenator(
    address _senator
  ) external virtual onlyChancellor nonReentrant {
    _quarantineSenator(_senator);
  }

  /**
   * @dev Unquarantine Senator from senate
   *
   * NOTE Anyone can unquarantine Senator if the quarantine period (expiration block) has passed and Senator was not banned
   *      The Senator voting power is restored and total supply corrected
   *
   */
  function unquarantineSenator(address _senator) external virtual nonReentrant {
    _unquarantineSenator(_senator);
  }

  /**
   * @dev Ban member from senate
   */
  function banFromSenate(
    address _token
  ) external virtual onlyChancellor nonReentrant {
    _banFromSenate(_token);
  }

  /**
   * @dev Ban Senator from senate
   */
  function banSenatorFromSenate(
    address _senator
  ) external virtual onlyChancellor nonReentrant {
    _banSenatorFromSenate(_senator);
  }

  /**
   * @dev Get quarantine block expiration of given Member
   */
  function quarantineUntil(address _token) external view returns (uint256) {
    return memberQuarantine[_token];
  }

  /**
   * @dev Get quarantine block expiration of given Senator
   */
  function senatorQuarantineUntil(
    address _senator
  ) external view returns (uint256) {
    return senatorQuarantine[_senator];
  }

  /**
   * @dev Get Senate Member Status
   */
  function senateMemberStatus(
    address _tokenAddress
  ) public view virtual override returns (membershipStatus) {
    if (banned.contains(_tokenAddress)) {
      return membershipStatus.BANNED_MEMBER;
    } else if (memberInQuarantine.contains(_tokenAddress)) {
      return membershipStatus.QUARANTINE_MEMBER;
    } else if (
      tokens.contains(_tokenAddress) || oldDogsTokens.contains(_tokenAddress)
    ) {
      return membershipStatus.ACTIVE_MEMBER;
    } else return membershipStatus.NOT_MEMBER;
  }

  /**
   * @dev Get Senator Member Status
   */
  function senatorStatus(
    address _senator
  ) public view virtual override returns (senateSenatorStatus) {
    if (senatorInQuarantine.contains(_senator)) {
      return senateSenatorStatus.QUARANTINE_SENATOR;
    } else if (senatorBanned.contains(_senator)) {
      return senateSenatorStatus.BANNED_SENATOR;
    } else if (_getVotes(_senator, block.number - 1, "") > 0) {
      return senateSenatorStatus.ACTIVE_SENATOR;
    } else {
      return senateSenatorStatus.NOT_SENATOR;
    }
  }

  /**
   * @dev Unquarantine member from senate
   *
   * NOTE Anyone can unquarantine Member if the quarantine period (expiration block) has passed and Member was not banned
   *      The Member voting power is restored and total supply corrected
   *
   */
  function _unquarantineFromSenate(address _token) internal {
    require(
      memberInQuarantine.contains(_token),
      "Senate::Senator Not In Quarantine"
    );
    require(
      memberQuarantine[_token] < block.number,
      "Senate::Quarantine not over"
    );
    require(!banned.contains(_token), "Senate::Already Banned");

    //restore member votes
    _restoreMemberVotings(_token);

    memberInQuarantine.remove(_token);

    emit MemberUnquarantined(_token);
  }

  /**
   * @dev Unquarantine Senator from senate
   *
   * NOTE Anyone can unquarantine Senator if the quarantine period (expiration block) has passed and Senator was not banned
   *      The Senator voting power is restored and total supply corrected
   *
   */
  function _unquarantineSenator(address _senator) internal {
    require(
      senatorInQuarantine.contains(_senator),
      "Senate::Senator Not In Quarantine"
    );
    require(
      senatorQuarantine[_senator] < block.number,
      "Senate::Quarantine not over"
    );
    require(!senatorBanned.contains(_senator), "Senate::Already Banned");

    //restore senatore votes
    _restoreSenatorVotings(_senator);

    senatorInQuarantine.remove(_senator);

    emit SenatorUnquarantined(_senator);
  }

  /**
   * @dev Quarantine Member from senate
   *
   * NOTE When Member is put under quarantine, the total supply must be corrected to avoid any distortion, on purpose or not, caused by the possible malicious member.
   *      The latest total suply of member is burned from senate books if the member is a SenatorVotes implementer.
   *      If the member is a Votes implementer there is no need for burn since we dont keep the records in senate books.
   *
   */
  function _quarantineFromSenate(address _token) internal {
    require(!banned.contains(_token), "Senate::Already Banned");

    memberQuarantine[_token] = block.number + quarantinePeriod;

    memberInQuarantine.add(_token);
    //burn suply from senate books
    _burnMemberVotings(_token);

    emit MemberQuarantined(_token);
  }

  /**
   * @dev Ban Member from senate
   *
   * NOTE When Member is banned, the total supply is corrected.
   *      The latest total suply of member is burned from senate books if the member is a SenatorVotes implementer.
   *      If the member is a Votes implementer there is no need for burn since we dont keep the records in senate books.
   *      If member is SenatorVotes implementer, Senators that represents the banned member wont be able to participate in the dao until they get rid of it.
   *
   */
  function _banFromSenate(address _token) internal {
    require(!banned.contains(_token), "Senate::Already Banned");

    banned.add(_token);

    //burn suply from senate books
    _burnMemberVotings(_token);

    emit MemberBanned(_token);
  }

  /**
   * @dev Quarantine Senator from senate
   *
   * NOTE When Senator is put under quarantine, the total supply must be corrected to avoid any distortion, on purpose or not, caused by the possible malicious senator.
   *      The latest senator voting power is burned from senate books.
   *      Total supply is corrected accordingly.
   *
   */
  function _quarantineSenator(address _senator) internal {
    require(
      !senatorInQuarantine.contains(_senator),
      "Senate::Already Quarantined"
    );
    require(!senatorBanned.contains(_senator), "Senate::Already Banned");

    senatorQuarantine[_senator] = block.number + quarantinePeriod;

    senatorInQuarantine.add(_senator);

    _burnSenatorVotings(_senator);

    emit SenatorQuarantined(_senator);
  }

  function _banSenatorFromSenate(address _senator) internal {
    require(!senatorBanned.contains(_senator), "Senate::Already Banned");

    senatorBanned.add(_senator);

    //burn voting power from senator
    _burnSenatorVotings(_senator);

    emit SenatorBanned(_senator);
  }

  /**
   * @dev Return a list of quarantined and banned members
   */
  function _getInaptMembers()
    internal
    view
    virtual
    override
    returns (address[] memory)
  {
    address[] memory _quarantinedMembers = memberInQuarantine.values();
    address[] memory _banned = banned.values();

    address[] memory _inaptMembers = new address[](
      _quarantinedMembers.length + _banned.length
    );
    uint256 counter = 0;

    for (uint256 idx = 0; idx < _quarantinedMembers.length; idx++) {
      _inaptMembers[counter++] = _quarantinedMembers[idx];
    }

    for (uint256 idx = 0; idx < _banned.length; idx++) {
      _inaptMembers[counter++] = _banned[idx];
    }

    return _inaptMembers;
  }

  /**
   * @dev Check if all members from list are valid.
   */
  function _validateMembers(
    bytes memory members
  ) internal view virtual override returns (bool) {
    for (uint256 idx = 0; idx < members.count(); idx++) {
      if (!_validateMember(members.getValue(idx))) return false;
    }

    return true;
  }

  /**
   * @dev Check if a given member is valid.
   */
  function _validateMember(
    uint32 member
  ) internal view virtual override returns (bool) {
    if (
      banned.contains(idMember[member]) ||
      memberInQuarantine.contains(idMember[member])
    ) return false;
    return true;
  }

  /**
   * @dev Check if senator is valid.
   */
  function _validateSenator(
    address senator
  ) internal view virtual override returns (bool) {
    if (
      senatorBanned.contains(senator) || senatorInQuarantine.contains(senator)
    ) return false;

    return true;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[43] private __gap;
}
