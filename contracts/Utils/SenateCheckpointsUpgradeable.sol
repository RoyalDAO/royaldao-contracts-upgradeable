// SPDX-License-Identifier: MIT
// RoyalDAO Contracts (last updated v1.2.0) (Governance/extensions/SenateVotesUpgradeable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../Utils/ArrayBytesUpgradeable.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * Built upon Openzeppelin's CheckpointsUpgradeable, this differ because allows to track checkpoints from different token contracts
 * beeing ideal to be used with the Senate pattern
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/CheckpointsUpgradeable.sol
 * _Available since v1.2.0
 */
library SenateCheckpointsUpgradeable {
  using BytesArrayLibAddressUpgradeable for bytes;

  struct History {
    mapping(address => Checkpoint[]) _checkpoints;
    address[] trackedContracts;
  }

  struct Checkpoint {
    uint32 _blockNumber;
    uint224 _value;
  }

  /**
   * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
   * before it is returned, or zero otherwise.
   */
  function getAtBlock(
    History storage self,
    address _token,
    uint256 blockNumber
  ) internal view returns (uint256) {
    require(blockNumber < block.number, "Checkpoints: block not yet mined");
    uint32 key = SafeCastUpgradeable.toUint32(blockNumber);

    uint256 len = self._checkpoints[_token].length;
    uint256 pos = _upperBinaryLookup(self._checkpoints[_token], key, 0, len);
    return
      pos == 0 ? 0 : _unsafeAccess(self._checkpoints[_token], pos - 1)._value;
  }

  /**
   * @dev Returns the value of all relevant members at a given block number. If a checkpoint is not available at that block, the closest one
   * before it is returned, or zero otherwise.
   */
  function getAtBlock(
    History storage self,
    uint256 blockNumber,
    address[] memory _inaptContracts
  ) internal view returns (uint256) {
    require(blockNumber < block.number, "Checkpoints: block not yet mined");
    uint32 key = SafeCastUpgradeable.toUint32(blockNumber);

    address[] memory _trackedContracts = self.trackedContracts;

    uint256 totalValue;

    for (uint256 idx = 0; idx < _trackedContracts.length; idx++) {
      if (contains(_inaptContracts, _trackedContracts[idx])) continue;

      uint256 len = self._checkpoints[_trackedContracts[idx]].length;
      uint256 pos = _upperBinaryLookup(
        self._checkpoints[_trackedContracts[idx]],
        key,
        0,
        len
      );
      totalValue += pos == 0
        ? 0
        : _unsafeAccess(self._checkpoints[_trackedContracts[idx]], pos - 1)
          ._value;
    }

    return totalValue;
  }

  /**
   * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
   * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
   * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
   * checkpoints.
   */
  function getAtProbablyRecentBlock(
    History storage self,
    address _token,
    uint256 blockNumber
  ) internal view returns (uint256) {
    require(blockNumber < block.number, "Checkpoints: block not yet mined");
    uint32 key = SafeCastUpgradeable.toUint32(blockNumber);

    uint256 len = self._checkpoints[_token].length;

    uint256 low = 0;
    uint256 high = len;

    if (len > 5) {
      uint256 mid = len - MathUpgradeable.sqrt(len);
      if (key < _unsafeAccess(self._checkpoints[_token], mid)._blockNumber) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    uint256 pos = _upperBinaryLookup(self._checkpoints[_token], key, low, high);

    return
      pos == 0 ? 0 : _unsafeAccess(self._checkpoints[_token], pos - 1)._value;
  }

  /**
   * @dev Returns the value of all relevant members at a given block number. If a checkpoint is not available at that block, the closest one
   * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
   * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
   * checkpoints.
   */
  function getAtProbablyRecentBlock(
    History storage self,
    uint256 blockNumber,
    address[] memory _inaptContracts
  ) internal view returns (uint256) {
    require(blockNumber < block.number, "Checkpoints: block not yet mined");
    uint32 key = SafeCastUpgradeable.toUint32(blockNumber);

    address[] memory _trackedContracts = self.trackedContracts;
    uint256 totalValue;

    for (uint256 idx = 0; idx < _trackedContracts.length; idx++) {
      if (contains(_inaptContracts, _trackedContracts[idx])) continue;

      address contractAddress = _trackedContracts[idx];
      uint256 len = self._checkpoints[contractAddress].length;

      uint256 low = 0;
      uint256 high = len;

      if (len > 5) {
        uint256 mid = len - MathUpgradeable.sqrt(len);
        if (
          key <
          _unsafeAccess(self._checkpoints[contractAddress], mid)._blockNumber
        ) {
          high = mid;
        } else {
          low = mid + 1;
        }
      }

      uint256 pos = _upperBinaryLookup(
        self._checkpoints[contractAddress],
        key,
        low,
        high
      );

      totalValue += pos == 0
        ? 0
        : _unsafeAccess(self._checkpoints[contractAddress], pos - 1)._value;
    }

    return totalValue;
  }

  /**
   * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
   *
   * Returns previous value and new value.
   */
  function push(
    History storage self,
    address _token,
    uint256 value
  ) internal returns (uint256, uint256) {
    if (!contains(self.trackedContracts, _token))
      self.trackedContracts.push(_token);

    return
      _insert(
        self._checkpoints[_token],
        SafeCastUpgradeable.toUint32(block.number),
        SafeCastUpgradeable.toUint224(value)
      );
  }

  /**
   * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
   * be set to `op(latest, delta)`.
   *
   * Returns previous value and new value.
   */
  function push(
    History storage self,
    address _token,
    function(uint256, uint256) view returns (uint256) op,
    uint256 delta
  ) internal returns (uint256, uint256) {
    //push to token tracker
    return push(self, _token, op(latest(self, _token), delta));
    //push to total tracker
    //return push(self, op(latest(self), delta));
  }

  /**
   * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
   */
  function latest(
    History storage self,
    address _token
  ) internal view returns (uint224) {
    uint256 pos = self._checkpoints[_token].length;
    return
      pos == 0 ? 0 : _unsafeAccess(self._checkpoints[_token], pos - 1)._value;
  }

  /**
   * @dev Returns the value of all relevant members in the most recent checkpoint, or zero if there are no checkpoints.
   */
  function latest(History storage self) internal view returns (uint224) {
    address[] memory _trackedContracts = self.trackedContracts;
    uint224 totalValue;

    for (uint256 idx = 0; idx < _trackedContracts.length; idx++) {
      uint256 pos = self._checkpoints[_trackedContracts[idx]].length;
      totalValue += pos == 0
        ? 0
        : _unsafeAccess(self._checkpoints[_trackedContracts[idx]], pos - 1)
          ._value;
    }

    return totalValue;
  }

  /**
   * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
   * in the most recent checkpoint.
   */
  function latestCheckpoint(
    History storage self,
    address _token
  ) internal view returns (bool exists, uint32 _blockNumber, uint224 _value) {
    uint256 pos = self._checkpoints[_token].length;
    if (pos == 0) {
      return (false, 0, 0);
    } else {
      Checkpoint memory ckpt = _unsafeAccess(
        self._checkpoints[_token],
        pos - 1
      );
      return (true, ckpt._blockNumber, ckpt._value);
    }
  }

  function contains(
    address[] memory list,
    address value
  ) private pure returns (bool) {
    for (uint256 idx = 0; idx < list.length; idx++) {
      if (list[idx] == value) return true;
    }

    return false;
  }

  /**
   * @dev Returns the number of checkpoint.
   */
  function length(
    History storage self,
    address _token
  ) internal view returns (uint256) {
    return self._checkpoints[_token].length;
  }

  /**
   * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
   * or by updating the last one.
   */
  function _insert(
    Checkpoint[] storage self,
    uint32 key,
    uint224 value
  ) private returns (uint224, uint224) {
    uint256 pos = self.length;

    if (pos > 0) {
      // Copying to memory is important here.
      Checkpoint memory last = _unsafeAccess(self, pos - 1);

      // Checkpoints keys must be increasing.
      require(last._blockNumber <= key, "Checkpoint: invalid key");

      // Update or push new checkpoint
      if (last._blockNumber == key) {
        _unsafeAccess(self, pos - 1)._value = value;
      } else {
        self.push(Checkpoint({_blockNumber: key, _value: value}));
      }
      return (last._value, value);
    } else {
      self.push(Checkpoint({_blockNumber: key, _value: value}));
      return (0, value);
    }
  }

  /**
   * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
   * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
   *
   * WARNING: `high` should not be greater than the array's length.
   */
  function _upperBinaryLookup(
    Checkpoint[] storage self,
    uint32 key,
    uint256 low,
    uint256 high
  ) private view returns (uint256) {
    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (_unsafeAccess(self, mid)._blockNumber > key) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return high;
  }

  /**
   * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
   * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
   *
   * WARNING: `high` should not be greater than the array's length.
   */
  function _lowerBinaryLookup(
    Checkpoint[] storage self,
    uint32 key,
    uint256 low,
    uint256 high
  ) private view returns (uint256) {
    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (_unsafeAccess(self, mid)._blockNumber < key) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return high;
  }

  function _unsafeAccess(
    Checkpoint[] storage self,
    uint256 pos
  ) private pure returns (Checkpoint storage result) {
    assembly {
      mstore(0, self.slot)
      result.slot := add(keccak256(0, 0x20), pos)
    }
  }

  struct Trace224 {
    mapping(address => Checkpoint224[]) _checkpoints;
    address[] trackedContracts;
  }

  struct Checkpoint224 {
    uint32 _key;
    uint224 _value;
  }

  /**
   * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
   *
   * Returns previous value and new value.
   */
  function push(
    Trace224 storage self,
    address _token,
    uint32 key,
    uint224 value
  ) internal returns (uint224, uint224) {
    if (!contains(self.trackedContracts, _token))
      self.trackedContracts.push(_token);
    return _insert(self._checkpoints[_token], key, value);
  }

  /**
   * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
   */
  function lowerLookup(
    Trace224 storage self,
    address _token,
    uint32 key
  ) internal view returns (uint224) {
    uint256 len = self._checkpoints[_token].length;
    uint256 pos = _lowerBinaryLookup(self._checkpoints[_token], key, 0, len);
    return
      pos == len ? 0 : _unsafeAccess(self._checkpoints[_token], pos)._value;
  }

  /**
   * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
   */
  function upperLookup(
    Trace224 storage self,
    address _token,
    uint32 key
  ) internal view returns (uint224) {
    uint256 len = self._checkpoints[_token].length;
    uint256 pos = _upperBinaryLookup(self._checkpoints[_token], key, 0, len);
    return
      pos == 0 ? 0 : _unsafeAccess(self._checkpoints[_token], pos - 1)._value;
  }

  /**
   * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
   */
  function latest(
    Trace224 storage self,
    address _token
  ) internal view returns (uint224) {
    uint256 pos = self._checkpoints[_token].length;
    return
      pos == 0 ? 0 : _unsafeAccess(self._checkpoints[_token], pos - 1)._value;
  }

  /**
   * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
   * in the most recent checkpoint.
   */
  function latestCheckpoint(
    Trace224 storage self,
    address _token
  ) internal view returns (bool exists, uint32 _key, uint224 _value) {
    uint256 pos = self._checkpoints[_token].length;
    if (pos == 0) {
      return (false, 0, 0);
    } else {
      Checkpoint224 memory ckpt = _unsafeAccess(
        self._checkpoints[_token],
        pos - 1
      );
      return (true, ckpt._key, ckpt._value);
    }
  }

  /**
   * @dev Returns the number of checkpoint.
   */
  function length(
    Trace224 storage self,
    address _token
  ) internal view returns (uint256) {
    return self._checkpoints[_token].length;
  }

  /**
   * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
   * or by updating the last one.
   */
  function _insert(
    Checkpoint224[] storage self,
    uint32 key,
    uint224 value
  ) private returns (uint224, uint224) {
    uint256 pos = self.length;

    if (pos > 0) {
      // Copying to memory is important here.
      Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

      // Checkpoints keys must be increasing.
      require(last._key <= key, "Checkpoint: invalid key");

      // Update or push new checkpoint
      if (last._key == key) {
        _unsafeAccess(self, pos - 1)._value = value;
      } else {
        self.push(Checkpoint224({_key: key, _value: value}));
      }
      return (last._value, value);
    } else {
      self.push(Checkpoint224({_key: key, _value: value}));
      return (0, value);
    }
  }

  /**
   * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
   * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
   *
   * WARNING: `high` should not be greater than the array's length.
   */
  function _upperBinaryLookup(
    Checkpoint224[] storage self,
    uint32 key,
    uint256 low,
    uint256 high
  ) private view returns (uint256) {
    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (_unsafeAccess(self, mid)._key > key) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return high;
  }

  /**
   * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
   * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
   *
   * WARNING: `high` should not be greater than the array's length.
   */
  function _lowerBinaryLookup(
    Checkpoint224[] storage self,
    uint32 key,
    uint256 low,
    uint256 high
  ) private view returns (uint256) {
    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (_unsafeAccess(self, mid)._key < key) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return high;
  }

  function _unsafeAccess(
    Checkpoint224[] storage self,
    uint256 pos
  ) private pure returns (Checkpoint224 storage result) {
    assembly {
      mstore(0, self.slot)
      result.slot := add(keccak256(0, 0x20), pos)
    }
  }

  struct Trace160 {
    mapping(address => Checkpoint160[]) _checkpoints;
    address[] trackedContracts;
  }

  struct Checkpoint160 {
    uint96 _key;
    uint160 _value;
  }

  /**
   * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
   *
   * Returns previous value and new value.
   */
  function push(
    Trace160 storage self,
    address _token,
    uint96 key,
    uint160 value
  ) internal returns (uint160, uint160) {
    if (!contains(self.trackedContracts, _token))
      self.trackedContracts.push(_token);
    return _insert(self._checkpoints[_token], key, value);
  }

  /**
   * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
   */
  function lowerLookup(
    Trace160 storage self,
    address _token,
    uint96 key
  ) internal view returns (uint160) {
    uint256 len = self._checkpoints[_token].length;
    uint256 pos = _lowerBinaryLookup(self._checkpoints[_token], key, 0, len);
    return
      pos == len ? 0 : _unsafeAccess(self._checkpoints[_token], pos)._value;
  }

  /**
   * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
   */
  function upperLookup(
    Trace160 storage self,
    address _token,
    uint96 key
  ) internal view returns (uint160) {
    uint256 len = self._checkpoints[_token].length;
    uint256 pos = _upperBinaryLookup(self._checkpoints[_token], key, 0, len);
    return
      pos == 0 ? 0 : _unsafeAccess(self._checkpoints[_token], pos - 1)._value;
  }

  /**
   * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
   */
  function latest(
    Trace160 storage self,
    address _token
  ) internal view returns (uint160) {
    uint256 pos = self._checkpoints[_token].length;
    return
      pos == 0 ? 0 : _unsafeAccess(self._checkpoints[_token], pos - 1)._value;
  }

  /**
   * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
   * in the most recent checkpoint.
   */
  function latestCheckpoint(
    Trace160 storage self,
    address _token
  ) internal view returns (bool exists, uint96 _key, uint160 _value) {
    uint256 pos = self._checkpoints[_token].length;
    if (pos == 0) {
      return (false, 0, 0);
    } else {
      Checkpoint160 memory ckpt = _unsafeAccess(
        self._checkpoints[_token],
        pos - 1
      );
      return (true, ckpt._key, ckpt._value);
    }
  }

  /**
   * @dev Returns the number of checkpoint.
   */
  function length(
    Trace160 storage self,
    address _token
  ) internal view returns (uint256) {
    return self._checkpoints[_token].length;
  }

  /**
   * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
   * or by updating the last one.
   */
  function _insert(
    Checkpoint160[] storage self,
    uint96 key,
    uint160 value
  ) private returns (uint160, uint160) {
    uint256 pos = self.length;

    if (pos > 0) {
      // Copying to memory is important here.
      Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

      // Checkpoints keys must be increasing.
      require(last._key <= key, "Checkpoint: invalid key");

      // Update or push new checkpoint
      if (last._key == key) {
        _unsafeAccess(self, pos - 1)._value = value;
      } else {
        self.push(Checkpoint160({_key: key, _value: value}));
      }
      return (last._value, value);
    } else {
      self.push(Checkpoint160({_key: key, _value: value}));
      return (0, value);
    }
  }

  /**
   * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
   * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
   *
   * WARNING: `high` should not be greater than the array's length.
   */
  function _upperBinaryLookup(
    Checkpoint160[] storage self,
    uint96 key,
    uint256 low,
    uint256 high
  ) private view returns (uint256) {
    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (_unsafeAccess(self, mid)._key > key) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return high;
  }

  /**
   * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
   * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
   *
   * WARNING: `high` should not be greater than the array's length.
   */
  function _lowerBinaryLookup(
    Checkpoint160[] storage self,
    uint96 key,
    uint256 low,
    uint256 high
  ) private view returns (uint256) {
    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (_unsafeAccess(self, mid)._key < key) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return high;
  }

  function _unsafeAccess(
    Checkpoint160[] storage self,
    uint256 pos
  ) private pure returns (Checkpoint160 storage result) {
    assembly {
      mstore(0, self.slot)
      result.slot := add(keccak256(0, 0x20), pos)
    }
  }
}
