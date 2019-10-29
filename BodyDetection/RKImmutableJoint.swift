//
//  RKImmutableJoint.swift
//  Motion Recorder
//
//  Created by Enzo Maruffa Moreira on 28/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import RealityKit

class RKImmutableJoint: Codable {
    
    /// A String with the joint's name
    let name: String
    
    /// A SIMD3<Float> with the joint's position relative to it's parent
    let relativeTranslation: SIMD3<Float>
    
    let absoluteTranslation: SIMD3<Float>
    
    /// A SIMD4<Float> with the joint's position relative to it's parent
    let rotation: SIMD4<Float>
    
    /// A list of the joint's children
    var childrenJoints: [RKImmutableJoint] = []
    
    /// An optional parent  joint
    var parent: RKImmutableJoint?
    
    /// The amount of descendants this joint has, recursevely calculated by each children.
    var descendantCount: Int {
        // Start with a count of 0 then sum each child descendantCount. Then, add the  total children joints this joint has to the sum.
        return childrenJoints.reduce(0, { $0 + $1.descendantCount }) + childrenJoints.count
    }
    
    init(name: String, relativeTranslation: SIMD3<Float>, absoluteTranslation: SIMD3<Float>, rotation: SIMD4<Float>, childrenJoints: [RKImmutableJoint], parent: RKImmutableJoint?) {
        self.name = name
        self.relativeTranslation = relativeTranslation
        self.absoluteTranslation = absoluteTranslation
        self.rotation = rotation
        self.childrenJoints = childrenJoints
        self.parent = parent
    }
    
    convenience init(joint: RKJoint) {
        self.init(name: joint.name, relativeTranslation: joint.relativeTranslation, absoluteTranslation: joint.absoluteTranslation, rotation: joint.rotation, childrenJoints: [], parent: nil)
    }
    
    /// Creates and adds a joint as a child based on it's name and translation
   /// - Parameter joint: An RKImmutableJoint with the to be children joint
   func addChild(joint: RKImmutableJoint) {
       // Checks if the joint to be added already has a parent
       if let oldParent = joint.parent {
           oldParent.childrenJoints.removeAll(where: { $0.name == joint.name} )
       }
       
       childrenJoints.append(joint)
       joint.parent = self
   }
    

    /// Searchs for a joint on this joint's children by name
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findChildrenBy(name: String) -> RKImmutableJoint? {
        return self.childrenJoints.filter( {$0.name == name} ).first
    }
    
    /// Searchs for a joint on this joint's descendants by name
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findDescendantBy(name: String) -> RKImmutableJoint? {
        // If it's a direct children, instantly returns it
        if let joint = self.findChildrenBy(name: name) {
            return joint
        }
        
        // Searches for a descentand in our children, find the first non nil and return it
        let returnJoint = childrenJoints.map( { $0.findDescendantBy(name: name)} ).filter( {$0 != nil} ).first
        return returnJoint ?? nil //TODO: Entender esse RKImmutableJoint??
        
    }
    
    /// Searchs for a joint on this joint's descendants by name, but also checks if this joint is the searched one
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findSelfOrDescendantBy(name: String) -> RKImmutableJoint? {
        if name == self.name {
            return self
        }
        
        return findDescendantBy(name: name)
    }
    
}


extension RKImmutableJoint: CustomStringConvertible {
    var description: String {
        return "\(name) | absolute: \(absoluteTranslation) | rotation: \(rotation)"
    }
}
