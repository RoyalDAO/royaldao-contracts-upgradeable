// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.2.0) (Governance/extensions/SenateVotesUpgradeable.sol)
/*
 * @title Solidity Bytes Uint Array Management
 *
 * @dev Utility library to manage uint arrays (32) or address arrays in bytes form for ethereum contracts written in Solidity.
 *      The library lets manage bytes as a normal array
 *      You can concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library BytesArrayLib32Upgradeable {
  using BytesLib for bytes;

  function insert(
    bytes memory _self,
    uint32 _value
  ) internal pure returns (bytes memory result) {
    if (!contains(_self, _value)) return _self.concat(abi.encodePacked(_value));
  }

  function insertStorage(bytes storage _self, uint32 _value) internal {
    if (!contains(_self, _value)) _self.concatStorage(abi.encodePacked(_value));
  }

  function remove(
    bytes memory _self,
    uint32 _value
  ) internal pure returns (bytes memory) {
    bytes memory newBytes;

    for (uint256 idx = 0; idx < (_self.length / 0x04); idx++) {
      uint32 storedValue = _self.toUint32(0x04 * idx);
      if (storedValue != _value) newBytes = insert(newBytes, storedValue);
    }
    return newBytes;
  }

  function contains(
    bytes memory _self,
    uint32 _value
  ) internal pure returns (bool) {
    for (uint256 idx = 0; idx < (_self.length / 0x04); idx++) {
      uint32 storedValue = _self.toUint32(0x04 * idx);
      if (storedValue == _value) return true;
    }
    return false;
  }

  function count(bytes memory _self) internal pure returns (uint256) {
    return (_self.length / 0x04);
  }

  function getValue(
    bytes memory _self,
    uint256 _index
  ) internal pure returns (uint32) {
    //return _self.toUint32(_index);
    return _self.toUint32(0x04 * _index);
  }

  function getArrayStorage(
    bytes storage _self
  ) internal view returns (uint32[] memory _array) {
    _array = new uint32[](_self.length / 0x04);
    //_array[0] = _self.toUint32(0);
    for (uint256 idx = 0; idx < _array.length; idx++) {
      _array[idx] = _self.toUint32(0x04 * idx);
    }

    return _array;
  }

  function getArray(
    bytes memory _self
  ) internal pure returns (uint32[] memory _array) {
    _array = new uint32[](_self.length / 0x04);
    //_array[0] = _self.toUint32(0);
    for (uint256 idx = 0; idx < _array.length; idx++) {
      _array[idx] = _self.toUint32(0x04 * idx);
    }

    return _array;
  }
}

library BytesArrayLibAddressUpgradeable {
  using BytesLib for bytes;

  function parse(
    address[] memory _self
  ) internal pure returns (bytes memory result) {
    result = "";
    for (uint256 idx = 0; idx < _self.length; idx++) {
      result = insert(result, _self[idx]);
    }
    return result;
  }

  function insert(
    bytes memory _self,
    address _value
  ) internal pure returns (bytes memory result) {
    if (!contains(_self, _value)) return _self.concat(abi.encodePacked(_value));
  }

  function insertStorage(bytes storage _self, address _value) internal {
    if (!contains(_self, _value)) _self.concatStorage(abi.encodePacked(_value));
  }

  function remove(
    bytes memory _self,
    address _value
  ) internal pure returns (bytes memory) {
    bytes memory newBytes;

    for (uint256 idx = 0; idx < (_self.length / 0x20); idx++) {
      address storedValue = _self.toAddress(0x20 * idx);
      if (storedValue != _value) newBytes = insert(newBytes, storedValue);
    }
    return newBytes;
  }

  function contains(
    bytes memory _self,
    address _value
  ) internal pure returns (bool) {
    for (uint256 idx = 0; idx < (_self.length / 0x20); idx++) {
      address storedValue = _self.toAddress(0x20 * idx);
      if (storedValue == _value) return true;
    }
    return false;
  }

  function count(bytes memory _self) internal pure returns (uint256) {
    return (_self.length / 0x20);
  }

  function getValue(
    bytes memory _self,
    uint256 _index
  ) internal pure returns (address) {
    //return _self.toUint32(_index);
    return _self.toAddress(0x20 * _index);
  }

  function getArrayStorage(
    bytes storage _self
  ) internal view returns (address[] memory _array) {
    _array = new address[](_self.length / 0x20);
    //_array[0] = _self.toUint32(0);
    for (uint256 idx = 0; idx < _array.length; idx++) {
      _array[idx] = _self.toAddress(0x20 * idx);
    }

    return _array;
  }

  function getArray(
    bytes memory _self
  ) internal pure returns (address[] memory _array) {
    _array = new address[](_self.length / 0x20);
    //_array[0] = _self.toUint32(0);
    for (uint256 idx = 0; idx < _array.length; idx++) {
      _array[idx] = _self.toAddress(0x20 * idx);
    }

    return _array;
  }
}
