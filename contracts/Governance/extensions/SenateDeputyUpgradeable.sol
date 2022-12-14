// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.0.0) (Governance/extensions/SenateDeputy.sol)
// Uses OpenZeppelin Contracts and Libraries

pragma solidity ^0.8.0;

import "../SenateUpgradeable.sol";

/**
 * @dev Extension of {SenateUpgradeable} to create the Deputy role.
 * @dev Deputy have some powers to keep the Senate safe from malicious members and/or senators
 *
 * _Available since v1._
 */
//TODO: Create Deputy Impeachment Process
//TODO: Create Deputy Payment
abstract contract SenateDeputyUpgradeable is SenateUpgradeable {
    /**
     * @dev Emitted when a new Deputy is nominated
     */
    event NewDeputyInTown(address newDeputy, uint256 mandateEndsAtBlock);
    /**
     * @dev Emitted when a Deputy Resigns his role
     */
    event DeputyResignation(address deputy, uint256 resignedAt);

    address public deputyMarshal;
    uint256 public mandatePeriod;

    mapping(address => uint256) internal deputyMandate;

    /**
     * @dev Exposes onlyMarshal modifier to be used as the implemeter's need
     */
    modifier onlyMarshal() {
        require(msg.sender == deputyMarshal, "Senate::Only deputy allowed!");
        _;
    }

    /**
     * @dev Set the senate.
     */
    function __SenateDeputy_init(address _deputyMarshal, uint256 _mandatePeriod)
        internal
        onlyInitializing
    {
        __SenateDeputy_init_unchained(_deputyMarshal, _mandatePeriod);
    }

    function __SenateDeputy_init_unchained(
        address _deputyMarshal,
        uint256 _mandatePeriod
    ) internal onlyInitializing {
        //set deputy mandate
        mandatePeriod = _mandatePeriod;
        _setNewDeputyMarshal(_deputyMarshal);
    }

    function changeDeputyMarshal(address _newMarshalInTown)
        external
        virtual
        onlyChancellor
    {
        _setNewDeputyMarshal(_newMarshalInTown);
    }

    function _setNewDeputyMarshal(address _newMarshalInTown) internal {
        require(
            deputyMandate[deputyMarshal] < block.number,
            "Senate::Mandate not ended!"
        );

        deputyMarshal = _newMarshalInTown;
        //set deputy mandate
        deputyMandate[deputyMarshal] = block.number + mandatePeriod;

        emit NewDeputyInTown(_newMarshalInTown, block.number + mandatePeriod);
    }

    function deputyResignation(address _currentDeputy)
        external
        virtual
        onlyMarshal
    {
        //set deputy final mandate block
        deputyMandate[_currentDeputy] = block.number;

        emit DeputyResignation(_currentDeputy, block.number);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}
