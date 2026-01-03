// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
import "../Structs/ShipmentStructures.sol";
import "../Structs/ActorStructures.sol";
import "../Structs/CheckpointsStructures.sol";
import "../Structs/IncidentStructures.sol";

interface IShipmentsManagement {
    event ShipmentCreated(
        uint256 indexed shipmentId,
        address indexed sender,
        address indexed recipient,
        string product
    );
    event ShipmentStatusChanged(
        uint256 indexed shipmentId,
        ShipmentStructures.ShipmentStatus newStatus
    );
    event DeliveryConfirmed(
        uint256 indexed shipmentId,
        address indexed recipient,
        uint256 timestamp
    );
    event CheckpointRecorded(
        uint256 indexed checkpointId,
        uint256 indexed shipmentId,
        string location,
        address actor
    );
    event IncidentReported(
        uint256 indexed incidentId,
        uint256 indexed shipmentId,
        IncidentStructures.IncidentType incidentType
    );
    event IncidentResolved(uint256 indexed incidentId);

    function createShipment(
        address _recipient,
        string memory _product,
        string memory _origin,
        string memory _destination,
        bool _requiresColdChain
    ) external returns (uint256);

    function getActorShipmentsData(
        uint256 _page,
        uint256 _pageSize
    ) external view returns (ShipmentStructures.Shipment[] memory);

    function getShipment(
        uint256 _shipmentId
    ) external view returns (ShipmentStructures.Shipment memory);

    function updateShipmentStatus(
        uint256 _shipmentId,
        ShipmentStructures.ShipmentStatus _newStatus
    ) external;

    function confirmDelivery(uint256 _shipmentId) external;

    function cancelShipment(uint256 _shipmentId) external;
    function verifyTemperatureCompliance(
        uint256 _shipmentId
    ) external view returns (bool);
    // Gestión de Checkpoints
    function recordCheckpoint(
        uint256 _shipmentId,
        string memory _location,
        string memory _checkpointType,
        string memory _notes,
        int256 _temperature
    ) external returns (uint256);

    function getCheckpoint(
        uint256 _checkpointId
    ) external view returns (CheckpointsStructures.Checkpoint memory);

    function getShipmentCheckpoints(
        uint256 _shipmentId
    ) external view returns (CheckpointsStructures.Checkpoint[] memory);
    // Gestión de Incidencias
    function reportIncident(
        uint256 _shipmentId,
        IncidentStructures.IncidentType _incidentType,
        string memory _description
    ) external returns (uint256);

    function resolveIncident(uint256 _incidentId) external;

    function getIncident(
        uint256 _incidentId
    ) external view returns (IncidentStructures.Incident memory);

    function getShipmentIncidents(
        uint256 _shipmentId
    ) external view returns (IncidentStructures.Incident[] memory);
}
