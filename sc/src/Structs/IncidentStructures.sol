// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library IncidentStructures {
    enum IncidentType { Delay, Damage, Lost, TempViolation, Unauthorized }
    struct Incident {
        uint256 id;
        uint256 shipmentId;
        IncidentType incidentType;
        address reporter;
        string description;
        uint256 timestamp;
        bool resolved;
    }
    
}