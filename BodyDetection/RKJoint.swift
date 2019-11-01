/**
//  RKJoint.swift
//  BodyDetection
//
//  Created by Enzo Maruffa Moreira on 22/10/19.
//  Copyright © 2019 Apple. All rights reserved.
*/

import RealityKit

/// A class representing a single mutable joint
class RKJoint: Codable {
    
    /// A String with the joint's name
    let name: String
    
    /// A calculated SIMD3<Float> with the joint's position relative to it's parent. Uses a moving window of size 9.
    var relativeTranslation: SIMD3<Float> {
        // Get our list with previous values
        let totalValues = relativeTranslations.reduce(SIMD3<Float>.zero, { $0 + $1 } )
        let count = Float(relativeTranslations.count)
        return SIMD3<Float>(x: totalValues.x / count, y: totalValues.y / count, z: totalValues.z / count)
    }
//    {
//        didSet {
//            self.absoluteTranslation = absoluteTranslation - oldValue + relativeTranslation
//        }
//    }
    
    /// A list with every last 5 relative joint translation snapshots. Used as a moving window for the relative translation property.
    var relativeTranslations: [SIMD3<Float>] = [] {
        didSet {
            if relativeTranslations.count > 5 {
                relativeTranslations.removeFirst()
            }
            print("Total relative count: \(relativeTranslations.count)")
        }
    }
    
    /** A computed property SIMD3<Float> with the joint's absolute position (relative to the scene anchor). */
    var absoluteTranslation: SIMD3<Float> {
        get {
            var defaultTranslation = SIMD3<Float>(0, 0, 0)
            if let parent = parent {
                defaultTranslation = parent.absoluteTranslation
            }
            return defaultTranslation + relativeTranslation
        }
    }
    
    /// A computed property SIMD4<Float> with the joint's position relative to it's parent. Uses a moving window of size 9.
    var rotation: SIMD4<Float> {
        let totalValues = rotations.reduce(SIMD4<Float>.zero, { $0 + $1 } )
        let count = Float(rotations.count)
        return SIMD4<Float>(x: totalValues.x / count, y: totalValues.y / count, z: totalValues.z / count, w: totalValues.w / count)
    }
    
    /// A list with every last 5 joint rotation snapshots. Used as a moving window for the rotation property.
    var rotations: [SIMD4<Float>] = [] {
        didSet {
            if rotations.count > 5 {
                rotations.removeFirst()
            }
        }
    }

    
    /// A list of the joint's children
    var childrenJoints: [RKJoint]
    
    /// An optional parent joint. Stored as a weak reference to prevent cycles
    weak var parent: RKJoint?
//    {
//        didSet {
//            if let parent = self.parent {
//                self.absoluteTranslation = parent.absoluteTranslation + self.relativeTranslation
//            }
//        }
//    }
    
    /// The amount of descendants this joint has, recursevely calculated by each children.
    var descendantCount: Int {
        // Start with a count of 0 then sum each child descendantCount. Then, add the  total children joints this joint has to the sum.
        return childrenJoints.reduce(0, { $0 + $1.descendantCount }) + childrenJoints.count
    }
    
    /// Initializes a joint using it's name, rotation and relative translation
    /// - Parameter jointName: A string with the joint's name
    /// - Parameter rotation: A SIMD4<Float> with the joint's rotation. xyz is the imaginary part, whilst the w is the real.
    /// - Parameter relativeTranslation: A SIMD3<Float> with the joint's relative translation
    init(jointName: String, rotation: SIMD4<Float>, relativeTranslation: SIMD3<Float>) {
        self.name = jointName
        self.relativeTranslations = [relativeTranslation]
        self.rotations = [rotation]
        self.childrenJoints = []
    }
    
    /// Initializes a joint using it's name and transform as a tuple
    /// - Parameter joint: A tuple with the joint's name and transform
    convenience init(joint: (String, Transform)) {
        self.init(jointName: joint.0, rotation: SIMD4<Float>(joint.1.rotation.imag, joint.1.rotation.real), relativeTranslation: joint.1.translation)
    }
    
    /// Initializes a joint using it's name, rotation and relative translation
    /// - Parameter jointName: A string with the joint's name
    /// - Parameter rotation: A simd_quatf with the joint's rotation
    /// - Parameter relativeTranslation: A SIMD3<Float> with the joint's relative translation
    convenience init(jointName: String, rotation: simd_quatf, relativeTranslation: SIMD3<Float>) {
        self.init(jointName: jointName, rotation: SIMD4<Float>(rotation.imag, rotation.real), relativeTranslation: relativeTranslation)
    }
    
    
    /// Creates and adds a joint as a child based on a tuple of a String and a Transform
    /// - Parameter joint: A tuple with the joint's name and translation
    /// - TODO: Store every Transform property instead of just the translation
    func addChild(joint: (String, Transform)) {
        let newJoint = RKJoint(joint: joint)
        childrenJoints.append(newJoint)
        newJoint.parent = self
    }
    
    /// Creates and adds a joint as a child based on it's name and translation
    /// - Parameter joint: An RKJoint with the to be children joint
    func addChild(joint: RKJoint) {
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
    func findChildrenBy(name: String) -> RKJoint? {
        return self.childrenJoints.filter( {$0.name == name} ).first
    }
    
    /// Searchs for a joint on this joint's descendants by name
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findDescendantBy(name: String) -> RKJoint? {
        // If it's a direct children, instantly returns it
        if let joint = self.findChildrenBy(name: name) {
            return joint
        }
        
        // Searches for a descentand in our children, find the first non nil and return it
        let returnJoint = childrenJoints.map( { $0.findDescendantBy(name: name)} ).filter( {$0 != nil} ).first
        return returnJoint ?? nil
        
    }
    
    /// Searchs for a joint on this joint's descendants by name, but also checks if this joint is the searched one
    /// - Parameter name: The searched joint's name
    /// - Returns: The searched joint if it was found. nil if no proper joint was found.
    func findSelfOrDescendantBy(name: String) -> RKJoint? {
        if name == self.name {
            return self
        }
        
        return findDescendantBy(name: name)
    }
    
    /// Checks the equivalence between two joints
    /// - Parameter to other: The joint that "self" will be compared to
    /// - Returns: a Bool with the comparison result
    func isEquivalent(to other: RKJoint) -> Bool {
        
        // If children count is different, instantly return as false
        if childrenJoints.count != other.childrenJoints.count {
            return false
        }
        
        for child in childrenJoints {
            // For each child, we check if the other joint contains a child with the same name. If so, we go down it's tree checking the same thing
            if let otherJoint = other.childrenJoints.filter( {$0.name == name} ).first {
                if !child.isEquivalent(to: otherJoint) {
                    return false
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    /// Copies a joint
    /// - Parameter withChildren: A boolean describing if it should copy also children
    /// - Returns: The joint's copy
    func copyJoint(withChildren: Bool) -> RKJoint {
        // Copies the original joint
        let newJoint = RKJoint(jointName: self.name, rotation: self.rotation, relativeTranslation: self.relativeTranslation)
        
        if !withChildren {
            return newJoint
        }
        
        // Recursevely copies each children
        for child in childrenJoints {
            newJoint.addChild(joint: child.copyJoint(withChildren: true))
        }
        
        return newJoint
    }
    
    
    /// Updates a joint's values
    /// - Parameter newTransform: The new transform
    /// - Parameter usingAbsoluteTranslation: A Bool describing if the new transform uses relative or absolute values
    func update(newTransform: Transform, usingAbsoluteTranslation: Bool) {

        if usingAbsoluteTranslation {
            relativeTranslations.append(newTransform.translation - (parent?.absoluteTranslation ?? .zero))
        } else {
            relativeTranslations.append(newTransform.translation)
        }
        
        rotations.append(SIMD4<Float>(newTransform.rotation.imag, newTransform.rotation.real))
    }
}


extension RKJoint: CustomStringConvertible {
    var description: String {
        return "\(name) | absolute: \(absoluteTranslation) | rotation: \(rotation)"
    }
}
