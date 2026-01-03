// SPDX-License-Identifier: UNLICENSED 
pragma solidity >=0.8.0 <0.9.0;
import "./Structs/ShipmentStructures.sol";
import "./Structs/ActorStructures.sol";
import "./Structs/CheckpointsStructures.sol";
import "./Structs/IncidentStructures.sol";
import "./Interfaces/IShipmentsManagement.sol";

contract ShipmentsManagement is IShipmentsManagement{
    uint256 public nextShipmentId = 1;
    uint256 public nextCheckpointId = 1;
    uint256 public nextIncidentId = 1;
    
    mapping(uint256 => ShipmentStructures.Shipment) public shipments;
    //Actor and shipments Id
    mapping(address => uint[]) public actorShipments;
    mapping(uint256 => CheckpointsStructures.Checkpoint) public checkpoints;
    mapping(uint256 => IncidentStructures.Incident) public incidents;

    modifier shipmentExists(uint256 _shipmentId) {
        require(_shipmentId > 0 && _shipmentId < nextShipmentId, "Shipment does not exist");
        _;
    }
    modifier checkpointExists(uint256 _checkpointId) {
        require(_checkpointId > 0 && _checkpointId < nextCheckpointId, "Checkpoint does not exist");
        _;
    }
    modifier incidentExists(uint256 _incidentId) {
        require(_incidentId > 0 && _incidentId < nextIncidentId, "Incident does not exist");
        _;
    }    
    function createShipment(address _recipient, string memory _product, string memory _origin, string memory _destination, bool _requiresColdChain) public returns (uint256) {
        uint256 shipmentId = nextShipmentId++;
        
        shipments[shipmentId] = ShipmentStructures.Shipment({
            id: shipmentId,
            sender: msg.sender,
            recipient: _recipient,
            currentHolder: msg.sender,
            product: _product,
            origin: _origin,
            destination: _destination,
            dateCreated: block.timestamp,
            dateDelivered: 0,
            status: ShipmentStructures.ShipmentStatus.Created,
            checkpointIds: new uint256[](0),
            incidentIds: new uint256[](0),
            requiresColdChain: _requiresColdChain
        });
        
        // Add shipment to sender's and recipient's lists
        actorShipments[msg.sender].push(shipmentId);
        actorShipments[_recipient].push(shipmentId);
        
        emit ShipmentCreated(shipmentId, msg.sender, _recipient, _product);
        return shipmentId;
    }
    
    function getActorShipmentsData(uint256 _page,uint256 _pageSize) public view returns (ShipmentStructures.Shipment[] memory) {
        uint256 totalShipments = actorShipments[msg.sender].length;
        uint256 startIndex = _page * _pageSize;
        uint256 endIndex = startIndex + _pageSize;
        if (endIndex > totalShipments) {
            endIndex = totalShipments;
        }
        
        ShipmentStructures.Shipment[] memory result = new ShipmentStructures.Shipment[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            uint256 shipmentId = actorShipments[msg.sender][i];
            result[i - startIndex] = shipments[shipmentId];
        }
        return result;
    }
    
    function getShipment(uint256 _shipmentId) public view shipmentExists(_shipmentId) returns (ShipmentStructures.Shipment memory) {
        return shipments[_shipmentId];
    }

    function updateShipmentStatus(uint256 _shipmentId, ShipmentStructures.ShipmentStatus _newStatus) public shipmentExists(_shipmentId) {
        shipments[_shipmentId].status = _newStatus;
        emit ShipmentStatusChanged(_shipmentId, _newStatus);
    }

    function confirmDelivery(uint256 _shipmentId) public  shipmentExists(_shipmentId) {
        require(msg.sender == shipments[_shipmentId].recipient, "Only recipient can confirm delivery");
        shipments[_shipmentId].status = ShipmentStructures.ShipmentStatus.Delivered;
        shipments[_shipmentId].dateDelivered = block.timestamp;
        emit DeliveryConfirmed(_shipmentId, msg.sender, block.timestamp);
    }

    function cancelShipment(uint256 _shipmentId) public  shipmentExists(_shipmentId) {
        require(msg.sender == shipments[_shipmentId].sender || msg.sender == shipments[_shipmentId].recipient, "Only sender or recipient can cancel shipment");
        shipments[_shipmentId].status = ShipmentStructures.ShipmentStatus.Cancelled;
        emit ShipmentStatusChanged(_shipmentId, ShipmentStructures.ShipmentStatus.Cancelled);
    }
    function verifyTemperatureCompliance(uint256 _shipmentId) public view shipmentExists(_shipmentId) returns (bool) {
        if (!shipments[_shipmentId].requiresColdChain) {
            return true; // No temperature requirements
        }
        
        CheckpointsStructures.Checkpoint[] memory shipmentCheckpoints = getShipmentCheckpoints(_shipmentId);
        for (uint256 i = 0; i < shipmentCheckpoints.length; i++) {
            // Temperature validation (example: between -5 and 10 degrees Celsius)
            if (shipmentCheckpoints[i].temperature < -50 || shipmentCheckpoints[i].temperature > 100) {
                return false;
            }
        }
        
        return true;
    }
    // Gestión de Checkpoints
    function recordCheckpoint(uint256 _shipmentId, string memory _location, string memory _checkpointType, string memory _notes, int256 _temperature) public returns (uint256) {
        require(shipments[_shipmentId].status != ShipmentStructures.ShipmentStatus.Cancelled && 
                shipments[_shipmentId].status != ShipmentStructures.ShipmentStatus.Delivered, 
                "Cannot record checkpoint for cancelled or delivered shipment");

        uint256 checkpointId = nextCheckpointId++;
        checkpoints[checkpointId] = CheckpointsStructures.Checkpoint({
            id: checkpointId,
            shipmentId: _shipmentId,
            actor: msg.sender,
            location: _location,
            checkpointType: _checkpointType,
            timestamp: block.timestamp,
            notes: _notes,
            temperature: _temperature
        });

        // Add checkpoint ID to shipment
        shipments[_shipmentId].checkpointIds.push(checkpointId);

        emit CheckpointRecorded(checkpointId, _shipmentId, _location, msg.sender);
        return checkpointId;
    }

    function getCheckpoint(uint256 _checkpointId) public view checkpointExists(_checkpointId) returns (CheckpointsStructures.Checkpoint memory) {
        return checkpoints[_checkpointId];
    }

    function getShipmentCheckpoints(uint256 _shipmentId) public view  returns (CheckpointsStructures.Checkpoint[] memory) {
        uint256[] memory checkpointIds = shipments[_shipmentId].checkpointIds;
        CheckpointsStructures.Checkpoint[] memory result = new CheckpointsStructures.Checkpoint[](checkpointIds.length);
        
        for (uint256 i = 0; i < checkpointIds.length; i++) {
            result[i] = checkpoints[checkpointIds[i]];
        }
        
        return result;
    }
        // Gestión de Incidencias
    function reportIncident(uint256 _shipmentId, IncidentStructures.IncidentType _incidentType, string memory _description) public shipmentExists(_shipmentId) returns (uint256) {
        require(shipments[_shipmentId].status != ShipmentStructures.ShipmentStatus.Cancelled, "Cannot report incident on cancelled shipment");

        uint256 incidentId = nextIncidentId++;
        incidents[incidentId] = IncidentStructures.Incident({
            id: incidentId,
            shipmentId: _shipmentId,
            incidentType: _incidentType,
            reporter: msg.sender,
            description: _description,
            timestamp: block.timestamp,
            resolved: false
        });

        // Add incident ID to shipment
        shipments[_shipmentId].incidentIds.push(incidentId);

        emit IncidentReported(incidentId, _shipmentId, _incidentType);
        return incidentId;
    }

    function resolveIncident(uint256 _incidentId) public incidentExists(_incidentId) {
        require(!incidents[_incidentId].resolved, "Incident already resolved");
        
        incidents[_incidentId].resolved = true;
        emit IncidentResolved(_incidentId);
    }

    function getIncident(uint256 _incidentId) public view incidentExists(_incidentId) returns (IncidentStructures.Incident memory) {
        return incidents[_incidentId];
    }

    function getShipmentIncidents(uint256 _shipmentId) public view shipmentExists(_shipmentId) returns (IncidentStructures.Incident[] memory) {
        uint256[] memory incidentIds = shipments[_shipmentId].incidentIds;
        IncidentStructures.Incident[] memory result = new IncidentStructures.Incident[](incidentIds.length);
        
        for (uint256 i = 0; i < incidentIds.length; i++) {
            result[i] = incidents[incidentIds[i]];
        }
        
        return result;
    }
}