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

    // Tests de creación de envíos
    function testCreateShipment() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);
        
        assertEq(shipmentId, 1);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(shipment.id, 1);
        assertEq(shipment.sender, sender);
        assertEq(shipment.recipient, recipient);
        assertEq(shipment.product, "Electronics");
        assertEq(shipment.origin, "New York");
        assertEq(shipment.destination, "Los Angeles");
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.Created));
        assertFalse(shipment.requiresColdChain);
    }

    function testCreateShipmentWithColdChain() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Medicine", "New York", "Los Angeles", true);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertTrue(shipment.requiresColdChain);
    }

    function testShipmentIdIncrementation() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId1 = supplyChain.createShipment(recipient, "Product 1", "Origin", "Destination", false);
        
        vm.prank(sender);
        uint256 shipmentId2 = supplyChain.createShipment(recipient, "Product 2", "Origin", "Destination", false);
        
        assertEq(shipmentId1, 1);
        assertEq(shipmentId2, 2);
    }

    function testGetShipment() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");

        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(shipment.id, 1);
    }

    function testOnlySenderCanCreateShipment() public {
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");
        
        vm.prank(recipient);
        // This test fails because the contract does not revert.
        // The `createShipment` function in `SupplyChain.sol` should have a role check like:
        // require(actors[msg.sender].role == ActorRole.Sender, "Only sender can create shipment");
        vm.expectRevert("Only sender can create shipment");
        supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);
    }
}
