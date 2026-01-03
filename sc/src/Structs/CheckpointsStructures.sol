// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library CheckpointsStructures {
    
    struct Checkpoint {
        uint256 id;
        uint256 shipmentId;
        address actor;
        string location;
        string checkpointType;     // "Pickup", "Hub", "Transit", "Delivery"
        uint256 timestamp;
        string notes;
        int256 temperature;        // Temperatura en celsius * 10 (para decimales)
    }
    
}