///
///  RKJointTree.swift
///  BodyDetection
///
///  Created by Enzo Maruffa Moreira on 22/10/19.
///  Copyright © 2019 Apple. All rights reserved.
///

import RealityKit

/// A tree representing an skeleton's joints
class RKJointTree {
    
    /// An optional RKJoint with the tree's root
    var rootJoint: RKJoint?
    
    /// An int that computes the tree size
    /// - Returns: nil if it has no rootJoint, an Int if it has a rootJoint
    var treeSize: Int? {
        if let rootJoint = self.rootJoint {
            return rootJoint.descendantCount + 1
        }
        return nil
    }
    
    ///
    init() { }
    
    init(rootJoint: (String, Transform)) {
        self.rootJoint = RKJoint(joint: rootJoint)
    }
    
    // Every joint must have a unique name
    init(from list: [(String, Transform)], usingAbsoluteTranslation: Bool) {
        
        // Separates our joint name in a list with it`s original hierarchy
        var hierachicalJoints = list.map( { ($0.0.components(separatedBy: "/"), $0.1)} )
        hierachicalJoints.sort(by: { $0.0.count < $1.0.count } )
        
        // Removes the root joint from  the list
        let rootJoint = hierachicalJoints.removeFirst()
        
        // Checks that the root joint exists
        guard let rootName = rootJoint.0.first else {
            return
        }
        
        // Creates the root joint in the tree
        self.rootJoint = RKJoint(joint: (rootName, rootJoint.1))
        
        for joint in hierachicalJoints {
            
            // If the joint has an ancestor, we get it's name
            let ancestorName = joint.0.count >= 2 ? joint.0[joint.0.count - 2] : rootName
            
            print(ancestorName)
            
            if let ancestorJoint = self.rootJoint?.findSelfOrDescendantBy(name: ancestorName) {

                let jointName = joint.0.last
                
                // If somehow a joint is repeated, we just update it's position
                if let existingJoint = ancestorJoint.childrenJoints.first(where: { $0.name == jointName} )  {
                    if usingAbsoluteTranslation {
                        existingJoint.relativeTranslation = joint.1.translation - ancestorJoint.absoluteTranslation
                    } else {
                        existingJoint.relativeTranslation = joint.1.translation
                    }
                    print("Repeated joint found with hierarchy \(joint.0)")
                } else {
                    
                    if usingAbsoluteTranslation {
                        let childJoint = RKJoint(jointName: jointName ?? "(nil)", rotation: joint.1.rotation, translation: joint.1.translation - ancestorJoint.absoluteTranslation)
                        ancestorJoint.addChild(joint: childJoint)
                    } else {
                        let childJoint = RKJoint(jointName: jointName ?? "(nil)", rotation: joint.1.rotation, translation: joint.1.translation)
                        ancestorJoint.addChild(joint: childJoint)
                    }
                }
            } else {
                print("Error creating RKJointTree. Ancestor for joint with hierarchy \(joint.0) not found")
            }
        }
        print("RKJointTree created successfully!")
    }
    
    ///TODO: Optimize since we already know where each joint is in the tree
    func updateJoints(from list: [(String, Transform)], usingAbsoluteTranslation: Bool) {
        
        // Separates our joint name in a list with it`s original hierarchy
        var hierachicalJoints = list.map( { ($0.0.components(separatedBy: "/"), $0.1)} )
        hierachicalJoints.sort(by: { $0.0.count < $1.0.count } )
        
        // Updates every joint
        for joint in hierachicalJoints {
            if let jointName = joint.0.last,
                let existingJoint = rootJoint?.findSelfOrDescendantBy(name: jointName) {
                
//                print("\nUpdating joint...")
//                print("    Updating \(jointName) from \(existingJoint.relativeTranslation) and \(existingJoint.absoluteTranslation) using absolute as \(usingAbsoluteTranslation).")
//                print("    New translation is \(joint.1.translation).")
                
                existingJoint.update(newTransform: joint.1, usingAbsoluteTranslation: usingAbsoluteTranslation)
                
//                print("    Updated \(jointName) to \(existingJoint.relativeTranslation) and \(existingJoint.absoluteTranslation)")
                
            }
        }
    }
    
    func printJointsBFS() {
        var jointQueue: [RKJoint] = []
        
        if let root = rootJoint {
            jointQueue.append(root)
        }
        
        while jointQueue.count > 0 {
            let joint = jointQueue.removeFirst()
            print(joint.description)
            jointQueue.append(contentsOf: joint.childrenJoints)
        }
    }
    
    func isEquivalent(to other: RKJointTree) -> Bool {
        guard let rootJoint = self.rootJoint, let otherRootJoint = other.rootJoint else {
            return false
        }
        
        if treeSize != other.treeSize {
            return false
        }
        
        // Compare the structure between two trees
        return rootJoint.isEquivalent(to: otherRootJoint)
    }
    
    
    func copy() -> RKJointTree {
        let newTree = RKJointTree()
        
        if let rootJoint = self.rootJoint {
            newTree.rootJoint = rootJoint.copyJoint(withChildren: true)
        }
        
        return newTree
    }
}


/// + operator overloading to allow the sum of two RKJointTree
/// - Parameter left: The leftmost tree
/// - Parameter right: the rightmost tree
/// - Returns: A new tree if the trees are equivalent.  Otherwise, returns  nil
func + (left: RKJointTree, right: RKJointTree) -> RKJointTree? {
    // Sum two trees only if they have the same structure
    if left.isEquivalent(to: right) {
        
        // We first copy the left tree
        let copiedTree = left.copy()
        
        // Then we operate on it's nodes and the second tree
        //TODO: Acabar a diferença entre funções
    }
    
    return nil
}

