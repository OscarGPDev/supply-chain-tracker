// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library ShipmentStructures {
    enum ShipmentStatus { Created, InTransit, AtHub, OutForDelivery, Delivered, Returned, Cancelled }
    struct Shipment {
        uint256 id;
        address sender;
        address recipient;
        address currentHolder;
        string product;
        string origin;
        string destination;
        uint256 dateCreated;
        uint256 dateDelivered;
        ShipmentStatus status;
        uint256[] checkpointIds;
        uint256[] incidentIds;
        bool requiresColdChain;    // Si requiere temperatura controlada
    }
    
}