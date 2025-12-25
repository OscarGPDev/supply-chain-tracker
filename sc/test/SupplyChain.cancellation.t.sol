// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/SupplyChain.sol";

contract CancellationTest is Test {
    SupplyChain supplyChain;
    address sender = address(0x2);
    address recipient = address(0x5);

    function setUp() public {
        supplyChain = new SupplyChain();
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.registerActor(recipient, "Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");
    }

    function testCancelShipment() public {
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.cancelShipment(shipmentId);
        
        SupplyChain.Shipment memory shipment = supplyChain.getShipment(shipmentId);
        assertEq(uint256(shipment.status), uint256(SupplyChain.ShipmentStatus.Cancelled));
    }

    function testOnlySenderCanCancelShipment() public {
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(recipient); // Try to cancel as recipient
        vm.expectRevert("Only sender or inspector can cancel shipment");
        supplyChain.cancelShipment(shipmentId);
    }

    function testCannotCancelDeliveredShipment() public {
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(recipient);
        supplyChain.confirmDelivery(shipmentId);
        
        vm.prank(sender);
        // This test fails because the contract does not revert.
        // The `cancelShipment` function in `SupplyChain.sol` should have a check like:
        // require(shipments[_shipmentId].status != ShipmentStatus.Delivered, "Cannot cancel a delivered shipment");
        vm.expectRevert("Cannot cancel delivered shipment");
        supplyChain.cancelShipment(shipmentId);
    }

    function testCannotCancelInTransitShipment() public {
        vm.prank(sender);
        uint256 shipmentId = supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);

        vm.prank(sender);
        supplyChain.updateShipmentStatus(shipmentId, SupplyChain.ShipmentStatus.InTransit);

        vm.prank(sender);
        vm.expectRevert("Cannot cancel shipment in transit");
        supplyChain.cancelShipment(shipmentId);
    }
}
