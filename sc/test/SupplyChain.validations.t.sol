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


    // Tests de validaciones
    function testCannotRecordCheckpointForNonExistentShipment() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");

        vm.prank(sender);
        vm.expectRevert();
        supplyChain.recordCheckpoint(1, "Location", "Pickup", "", 0);
    }

    function testCannotReportIncidentForNonExistentShipment() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");

        vm.prank(sender);
        vm.expectRevert();
        supplyChain.reportIncident(1, SupplyChain.IncidentType.Delay, "Description");
    }

    function testInactiveActorCannotRecordCheckpoint() public {
        supplyChain.registerActor(sender, "John Sender", SupplyChain.ActorRole.Sender, "New York");
        supplyChain.deactivateActor(sender);

        vm.prank(sender);
        vm.expectRevert();
        supplyChain.createShipment(recipient, "Electronics", "New York", "Los Angeles", false);
    }
}
