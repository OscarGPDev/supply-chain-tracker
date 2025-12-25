// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

contract SupplyChain {
    // ⚠️ TU TAREA: Definir estos enums
    enum ShipmentStatus { Created, InTransit, AtHub, OutForDelivery, Delivered, Returned, Cancelled }
    enum ActorRole { None, Sender, Carrier, Hub, Recipient, Inspector }
    enum IncidentType { Delay, Damage, Lost, TempViolation, Unauthorized }

    // ⚠️ TU TAREA: Implementar estos structs
    struct Shipment {
        uint256 id;
        address sender;
        address recipient;
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

    struct Incident {
        uint256 id;
        uint256 shipmentId;
        IncidentType incidentType;
        address reporter;
        string description;
        uint256 timestamp;
        bool resolved;
    }

    struct Actor {
        address actorAddress;
        string name;
        ActorRole role;
        string location;
        bool isActive;
    }

    // Variables de estado
    address public admin;
    uint256 public nextShipmentId = 1;
    uint256 public nextCheckpointId = 1;
    uint256 public nextIncidentId = 1;

    // Mappings
    mapping(uint256 => Shipment) public shipments;
    mapping(uint256 => Checkpoint) public checkpoints;
    mapping(uint256 => Incident) public incidents;
    mapping(address => Actor) public actors;

    // Eventos
    event ShipmentCreated(uint256 indexed shipmentId, address indexed sender, address indexed recipient, string product);
    event CheckpointRecorded(uint256 indexed checkpointId, uint256 indexed shipmentId, string location, address actor);
    event ShipmentStatusChanged(uint256 indexed shipmentId, ShipmentStatus newStatus);
    event IncidentReported(uint256 indexed incidentId, uint256 indexed shipmentId, IncidentType incidentType);
    event IncidentResolved(uint256 indexed incidentId);
    event DeliveryConfirmed(uint256 indexed shipmentId, address indexed recipient, uint256 timestamp);
    event ActorRegistered(address indexed actorAddress, string name, ActorRole role);

    constructor() {
        admin = msg.sender;
    }

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyActiveActor() {
        require(actors[msg.sender].isActive, "Actor is not active");
        _;
    }

    modifier shipmentExists(uint256 _shipmentId) {
        require(_shipmentId > 0 && _shipmentId < nextShipmentId, "Shipment does not exist");
        _;
    }

    modifier incidentExists(uint256 _incidentId) {
        require(_incidentId > 0 && _incidentId < nextIncidentId, "Incident does not exist");
        _;
    }

    modifier checkpointExists(uint256 _checkpointId) {
        require(_checkpointId > 0 && _checkpointId < nextCheckpointId, "Checkpoint does not exist");
        _;
    }

    // Gestión de Actores
    function registerActor(address _actorAddress,string memory _name, ActorRole _role, string memory _location) public onlyAdmin {
        require(actors[msg.sender].actorAddress == address(0), "Actor already registered");

        actors[_actorAddress] = Actor({
            actorAddress: _actorAddress,
            name: _name,
            role: _role,
            location: _location,
            isActive: true
        });

        emit ActorRegistered(msg.sender, _name, _role);
    }

    function getActor(address _actorAddress) public view returns (Actor memory) {
        return actors[_actorAddress];
    }

    function deactivateActor(address _actorAddress) public onlyAdmin {
        require(actors[_actorAddress].actorAddress != address(0), "Actor does not exist");
        actors[_actorAddress].isActive = false;
    }

    // Gestión de Envíos
    function createShipment(address _recipient, string memory _product, string memory _origin, string memory _destination, bool _requiresColdChain) public onlyActiveActor returns (uint256) {
        require(_recipient != address(0), "Invalid recipient address");
        require(actors[msg.sender].role == ActorRole.Sender, "Only sender can create shipment");
        
        uint256 shipmentId = nextShipmentId++;
        shipments[shipmentId] = Shipment({
            id: shipmentId,
            sender: msg.sender,
            recipient: _recipient,
            product: _product,
            origin: _origin,
            destination: _destination,
            dateCreated: block.timestamp,
            dateDelivered: 0,
            status: ShipmentStatus.Created,
            checkpointIds: new uint256[](0),
            incidentIds: new uint256[](0),
            requiresColdChain: _requiresColdChain
        });

        emit ShipmentCreated(shipmentId, msg.sender, _recipient, _product);
        return shipmentId;
    }

    function getShipment(uint256 _shipmentId) public view shipmentExists(_shipmentId) returns (Shipment memory) {
        return shipments[_shipmentId];
    }

    function updateShipmentStatus(uint256 _shipmentId, ShipmentStatus _newStatus) public onlyActiveActor shipmentExists(_shipmentId) {
        require(shipments[_shipmentId].sender == msg.sender || 
                shipments[_shipmentId].recipient == msg.sender ||
                actors[msg.sender].role == ActorRole.Carrier ||
                actors[msg.sender].role == ActorRole.Hub ||
                actors[msg.sender].role == ActorRole.Inspector, 
                "Only authorized actors can update shipment status");

        shipments[_shipmentId].status = _newStatus;
        emit ShipmentStatusChanged(_shipmentId, _newStatus);
    }

    function confirmDelivery(uint256 _shipmentId) public onlyActiveActor shipmentExists(_shipmentId) {
        require(shipments[_shipmentId].recipient == msg.sender, "Only recipient can confirm delivery");
        require(shipments[_shipmentId].status != ShipmentStatus.Delivered, "Shipment already delivered");

        shipments[_shipmentId].status = ShipmentStatus.Delivered;
        shipments[_shipmentId].dateDelivered = block.timestamp;
        emit DeliveryConfirmed(_shipmentId, msg.sender, block.timestamp);
    }

    function cancelShipment(uint256 _shipmentId) public onlyActiveActor shipmentExists(_shipmentId) {
        require(shipments[_shipmentId].sender == msg.sender || 
                actors[msg.sender].role == ActorRole.Inspector, 
                "Only sender or inspector can cancel shipment");
        require(shipments[_shipmentId].status != ShipmentStatus.Delivered, "Cannot cancel delivered shipment");
        require(shipments[_shipmentId].status == ShipmentStatus.Created, "Cannot cancel shipment in transit");
        shipments[_shipmentId].status = ShipmentStatus.Cancelled;
        emit ShipmentStatusChanged(_shipmentId, ShipmentStatus.Cancelled);
    }

    // Gestión de Checkpoints
    function recordCheckpoint(uint256 _shipmentId, string memory _location, string memory _checkpointType, string memory _notes, int256 _temperature) public onlyActiveActor shipmentExists(_shipmentId) returns (uint256) {
        require(shipments[_shipmentId].status != ShipmentStatus.Cancelled && 
                shipments[_shipmentId].status != ShipmentStatus.Delivered, 
                "Cannot record checkpoint for cancelled or delivered shipment");

        uint256 checkpointId = nextCheckpointId++;
        checkpoints[checkpointId] = Checkpoint({
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

    function getCheckpoint(uint256 _checkpointId) public view checkpointExists(_checkpointId) returns (Checkpoint memory) {
        return checkpoints[_checkpointId];
    }

    function getShipmentCheckpoints(uint256 _shipmentId) public view shipmentExists(_shipmentId) returns (Checkpoint[] memory) {
        uint256[] memory checkpointIds = shipments[_shipmentId].checkpointIds;
        Checkpoint[] memory result = new Checkpoint[](checkpointIds.length);
        
        for (uint256 i = 0; i < checkpointIds.length; i++) {
            result[i] = checkpoints[checkpointIds[i]];
        }
        
        return result;
    }

    // Gestión de Incidencias
    function reportIncident(uint256 _shipmentId, IncidentType _incidentType, string memory _description) public onlyActiveActor shipmentExists(_shipmentId) returns (uint256) {
        require(shipments[_shipmentId].status != ShipmentStatus.Cancelled, "Cannot report incident on cancelled shipment");

        uint256 incidentId = nextIncidentId++;
        incidents[incidentId] = Incident({
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

    function resolveIncident(uint256 _incidentId) public onlyActiveActor incidentExists(_incidentId) {
        require(!incidents[_incidentId].resolved, "Incident already resolved");
        
        incidents[_incidentId].resolved = true;
        emit IncidentResolved(_incidentId);
    }

    function getIncident(uint256 _incidentId) public view incidentExists(_incidentId) returns (Incident memory) {
        return incidents[_incidentId];
    }

    function getShipmentIncidents(uint256 _shipmentId) public view shipmentExists(_shipmentId) returns (Incident[] memory) {
        uint256[] memory incidentIds = shipments[_shipmentId].incidentIds;
        Incident[] memory result = new Incident[](incidentIds.length);
        
        for (uint256 i = 0; i < incidentIds.length; i++) {
            result[i] = incidents[incidentIds[i]];
        }
        
        return result;
    }

    // Funciones auxiliares
    function getActorShipments(address _actor) public view returns (uint256[] memory) {
        uint256 count = 0;
        // First pass to count shipments
        for (uint256 i = 1; i < nextShipmentId; i++) {
            if (shipments[i].sender == _actor || shipments[i].recipient == _actor) {
                count++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        // Second pass to fill array
        for (uint256 i = 1; i < nextShipmentId; i++) {
            if (shipments[i].sender == _actor || shipments[i].recipient == _actor) {
                result[index] = i;
                index++;
            }
        }
        
        return result;
    }

    function verifyTemperatureCompliance(uint256 _shipmentId) public view shipmentExists(_shipmentId) returns (bool) {
        if (!shipments[_shipmentId].requiresColdChain) {
            return true; // No temperature requirements
        }
        
        Checkpoint[] memory shipmentCheckpoints = getShipmentCheckpoints(_shipmentId);
        for (uint256 i = 0; i < shipmentCheckpoints.length; i++) {
            // Temperature validation (example: between -5 and 10 degrees Celsius)
            if (shipmentCheckpoints[i].temperature < -50 || shipmentCheckpoints[i].temperature > 100) {
                return false;
            }
        }
        
        return true;
    }
}
