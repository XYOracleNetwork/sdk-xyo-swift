//
//  XyoHumanName.swift
//  XYO
//
//  Created by Carter Harrison on 3/26/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Foundation
import sdk_core_swift

public struct XyoHumanName {
    public static func getHumanName (boundWitness: XyoBoundWitness, publicKey: XyoObjectStructure?) -> String {
        do {
            guard let numberOfParties = try boundWitness.getNumberOfParties() else {
                return "Invalid"
            }
            
            if (numberOfParties == 1) {
                return try XyoHumanName.handleSinglePartyBlock(boundWitness: boundWitness, publicKey: publicKey)
            }
            
            return try XyoHumanName.handleMultiPartyBlock(boundWitness: boundWitness, publicKey: publicKey)

        } catch {
            return "Invalid"
        }

    }
    
    private static func handleSinglePartyBlock (boundWitness: XyoBoundWitness, publicKey: XyoObjectStructure?) throws -> String {
        let indexOfParty = try XyoHumanName.getIndexForParty(boundWitness: boundWitness, index: 0)

        if (indexOfParty == 0) {
            return "Genesis Block!"
        }

        return "Self signed block"
    }
    
    private static func handleMultiPartyBlock (boundWitness: XyoBoundWitness, publicKey: XyoObjectStructure?) throws -> String {
        guard let safePublicKey = publicKey else {
            return "Regular Interaction"
        }

        guard let indexOfSelf = try XyoBoundWitnessUtil.getPartyNumberFromPublicKey(publickey: safePublicKey, boundWitness: boundWitness) else {
            return "Regular Interaction"
        }
        
        guard let numberOfBlocksSent = try XyoHumanName.getNumberOfBridgeBlocksForParty(boundWitness: boundWitness, index: indexOfSelf) else {
            guard let numberOfBlocksRecived = try XyoHumanName.getNumberOfBridgeBlocksForParty(boundWitness: boundWitness, index: XyoHumanName.getInverse(index: indexOfSelf)) else {
                return "Regular Interaction"
            }

            return "Received \(numberOfBlocksRecived) blocks"
        }

        return "Sent \(numberOfBlocksSent) blocks"
    }

    private static func getInverse (index: Int) -> Int {
        if (index == 0) {
            return 1
        }

        return 0
    }

    private static func getIndexForParty (boundWitness: XyoBoundWitness, index: Int) throws -> UInt {
        guard let fetter = try boundWitness.getFetterOfParty(partyIndex: index) else {
            throw XyoError.UNKNOWN_ERROR
        }

        guard let index = try fetter.get(id: XyoSchemas.INDEX.id).first else {
            throw XyoError.UNKNOWN_ERROR
        }
        
        let valueOfIndex = try index.getValueCopy().toByteArray()
        
        switch valueOfIndex.count {
        case 1: return UInt(valueOfIndex[0])
        case 2: return try UInt(index.getValueCopy().getUInt16(offset: 0))
        case 4: return try UInt(index.getValueCopy().getUInt32(offset: 0))
        default:
            // wrong index size if here
            throw XyoError.UNKNOWN_ERROR
        }
    }

    private static func getNumberOfBridgeBlocksForParty (boundWitness: XyoBoundWitness, index: Int) throws -> UInt? {
        guard let fetter = try boundWitness.getFetterOfParty(partyIndex: index) else {
            throw XyoError.UNKNOWN_ERROR
        }

        guard let hashSet = try fetter.get(id: XyoSchemas.BRIDGE_HASH_SET.id).first as? XyoIterableStructure else {
            return nil
        }

        return try UInt(hashSet.getCount())
    }
}
