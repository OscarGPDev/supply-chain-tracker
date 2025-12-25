// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/SupplyChain.sol";

contract LogisticsTrackingTest is Test {
    SupplyChain supplyChain;
    address admin = address(0x1);
    address sender = address(0x2);
    address carrier = address(0x3);
    address hub = address(0x4);
    address recipient = address(0x5);
    address inspector = address(0x6);

    function setUp() public {
        
        supplyChain = new SupplyChain();
        admin = msg.sender;
        //supplyChain.registerActor("Admin", SupplyChain.ActorRole.None, "Headquarters");
    }

    // Tests de incidencias
    function testReportDelayIncident() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Delay, "Delayed by 2 days");
        
        assertEq(incidentId, 1);
        
        SupplyChain.Incident memory incident = supplyChain.getIncident(incidentId);
        assertEq(incident.shipmentId, shipmentId);
        assertEq(uint256(incident.incidentType), uint256(SupplyChain.IncidentType.Delay));
        assertEq(incident.reporter, sender);
        assertEq(incident.description, "Delayed by 2 days");
        assertFalse(incident.resolved);
    }

    function testReportDamageIncident() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(recipient);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Damage, "Package damaged during transit");
        
        SupplyChain.Incident memory incident = supplyChain.getIncident(incidentId);
        assertEq(uint256(incident.incidentType), uint256(SupplyChain.IncidentType.Damage));
    }

    function testReportLostIncident() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        supplyChain.registerActor(inspector, "Inspector", SupplyChain.ActorRole.Inspector, "Global");
        vm.prank(inspector);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Lost, "Package lost in transit");
        
        SupplyChain.Incident memory incident = supplyChain.getIncident(incidentId);
        assertEq(uint256(incident.incidentType), uint256(SupplyChain.IncidentType.Lost));
    }

    function testReportTempViolation() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "New York", "Los Angeles", true);

        supplyChain.registerActor(inspector, "Inspector", SupplyChain.ActorRole.Inspector, "Global");
        vm.prank(inspector);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.TempViolation, "Temperature exceeded limits");
        
        SupplyChain.Incident memory incident = supplyChain.getIncident(incidentId);
        assertEq(uint256(incident.incidentType), uint256(SupplyChain.IncidentType.TempViolation));
    }

    function testResolveIncident() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        uint256 incidentId = supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Delay, "Delayed by 2 days");
        
        supplyChain.registerActor(inspector, "Inspector", SupplyChain.ActorRole.Inspector, "Global");
        vm.prank(inspector);
        supplyChain.resolveIncident(incidentId);
        
        SupplyChain.Incident memory incident = supplyChain.getIncident(incidentId);
        assertTrue(incident.resolved);
    }

    function testGetShipmentIncidents() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Delay, "Delayed");
        
        vm.prank(sender);
        supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Damage, "Damaged");
        
        SupplyChain.Incident[] memory incidents = supplyChain.getShipmentIncidents(shipmentId);
        assertEq(incidents.length, 2);
    }

    function testUnresolvedIncidentsList() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Delay, "Delayed");
        
        supplyChain.registerActor(inspector, "Inspector", SupplyChain.ActorRole.Inspector, "Global");
        vm.prank(inspector);
        supplyChain.reportIncident(shipmentId, SupplyChain.IncidentType.Damage, "Damaged");
        
        vm.prank(inspector);
        supplyChain.resolveIncident(2); // Resolve the second incident
        
        SupplyChain.Incident memory incident1 = supplyChain.getIncident(1);
        assertFalse(incident1.resolved); // First incident should be unresolved
    }

}
