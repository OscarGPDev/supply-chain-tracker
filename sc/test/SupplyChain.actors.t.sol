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

    // Tests de gestión de actores
    function testRegisterSender() public {
        //vm.prank(admin);
        supplyChain.registerActor(sender ,"John Sender", SupplyChain.ActorRole.Sender, "New York");
        
        SupplyChain.Actor memory actor = supplyChain.getActor(sender);
        assertEq(actor.actorAddress, sender);
        assertEq(actor.name, "John Sender");
        //assertEq(uint256(actor.role), uint256(SupplyChain.ActorRole.Sender));
        assertTrue(actor.isActive);
    }

    function testRegisterCarrier() public {
        //vm.prank(admin);
        supplyChain.registerActor(carrier, "Fast Cargo", SupplyChain.ActorRole.Carrier, "Chicago");
        
        SupplyChain.Actor memory actor = supplyChain.getActor(carrier);
        assertEq(actor.actorAddress, carrier);
        assertEq(actor.name, "Fast Cargo");
        assertEq(uint256(actor.role), uint256(SupplyChain.ActorRole.Carrier));
        assertTrue(actor.isActive);
    }

    function testRegisterHub() public {
        
        supplyChain.registerActor(hub,"Central Hub", SupplyChain.ActorRole.Hub, "Miami");
        
        SupplyChain.Actor memory actor = supplyChain.getActor(hub);
        assertEq(actor.actorAddress, hub);
        assertEq(actor.name, "Central Hub");
        assertEq(uint256(actor.role), uint256(SupplyChain.ActorRole.Hub));
        assertTrue(actor.isActive);
    }

    function testRegisterRecipient() public {
       
        supplyChain.registerActor(recipient,"Jane Recipient", SupplyChain.ActorRole.Recipient, "Los Angeles");
        
        SupplyChain.Actor memory actor = supplyChain.getActor(recipient);
        assertEq(actor.actorAddress, recipient);
        assertEq(actor.name, "Jane Recipient");
        assertEq(uint256(actor.role), uint256(SupplyChain.ActorRole.Recipient));
        assertTrue(actor.isActive);
    }

    function testDeactivateActor() public {
        
        supplyChain.registerActor(sender,"Test Actor", SupplyChain.ActorRole.Sender, "Location");
        
        SupplyChain.Actor memory actorBefore = supplyChain.getActor(sender);
        assertTrue(actorBefore.isActive);
        
        
        supplyChain.deactivateActor(sender);
        
        SupplyChain.Actor memory actorAfter = supplyChain.getActor(sender);
        assertFalse(actorAfter.isActive);
    }
}
