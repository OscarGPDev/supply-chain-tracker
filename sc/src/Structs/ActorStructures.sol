// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

library ActorStructures {
    enum ActorRole { None, Sender, Carrier, Hub, Recipient, Inspector }
    
    struct Actor {
        address actorAddress;
        string name;
        ActorRole role;
        string location;
        bool isActive;
    }
}
