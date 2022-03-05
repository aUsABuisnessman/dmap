/// SPDX-License-Identifier: AGPL-3.0

// One day, someone is going to try very hard to prevent you
// from accessing one of these storage slots.

pragma solidity 0.8.11;

contract Dmap {
    // storage: hash(zone, key) -> (value, flags)
    // flags: locked (2^0) & appflags
    // log4: zone, key, value, flags
    // err: "LOCK"

    constructor(address rootzone) {
        assembly {
            sstore(0, shl(96, rootzone))
            sstore(1, 3) // locked & 2^1
        }
    }

    function raw(bytes32 slot) external view
      returns (bytes32 value, bytes32 flags) {
        assembly {
            value := sload(slot)
            flags := sload(add(slot, 1))
        }
    }

    function get(address zone, bytes32 key) external view
      returns (bytes32 value, bytes32 flags) {
        assembly {
            mstore(0, zone)
            mstore(32, key)
            let slot := keccak256(0, 64)
            value := sload(slot)
            flags := sload(add(slot, 1))
        }
    }

    function set(bytes32 key, bytes32 value, bytes32 flags) external {
        assembly {
            mstore(0, caller())
            mstore(32, key)
            let slot0 := keccak256(0, 64)
            let slot1 := add(slot0, 1)
            if eq(1, and(1, sload(slot1))) { revert("LOCK", 4) }
            sstore(slot0, value)
            sstore(slot1, flags)
            log4(0, 0, caller(), key, value, flags)
        }
    }

    function slot(address zone, bytes32 key) external pure returns (bytes32) {
        return keccak256(abi.encode(zone, key));
    }

}
