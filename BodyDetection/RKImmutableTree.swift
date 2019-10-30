//
//  RKImmutableTree.swift
//  Motion Recorder
//
//  Created by Enzo Maruffa Moreira on 28/10/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import RealityKit

/// An immutable tree representing an skeleton's joints
class RKImmutableJointTree: Codable {
    
    /// An optional RKJoint with the tree's root
    let rootJoint: RKImmutableJoint?
    
    /// An int that computes the tree size
    /// - Returns: nil if it has no rootJoint, an Int if it has a rootJoint
    var treeSize: Int? {
        if let rootJoint = self.rootJoint {
            return rootJoint.descendantCount + 1
        }
        return nil
    }
    
    
    // Every joint must have a unique name
    init(from tree: RKJointTree) {
        
        // Creates the root joint in the tree
        if let treeRoot = tree.rootJoint {
            self.rootJoint = RKImmutableJoint(joint: treeRoot)
            
            var jointQueue: [(RKJoint, RKImmutableJoint)] = []
            
            // Adds every joint in the root to the queue
            jointQueue.append(contentsOf: treeRoot.childrenJoints.map( { ($0, self.rootJoint!) } ))
            
            while jointQueue.count > 0 {
                let (joint, ancestor) = jointQueue.removeFirst()
                let immutableJoint = RKImmutableJoint(joint: joint)
                ancestor.addChild(joint: immutableJoint)
                
                // Adds every child in the joint to the queue
                jointQueue.append(contentsOf: joint.childrenJoints.map( { ($0, immutableJoint) } ))
            }
            
            print("RKImmutableJointTree created successfully!")
        } else {
            self.rootJoint = nil
        }
    }
    
    func printJointsBFS() {
        var jointQueue: [RKImmutableJoint] = []
        
        if let root = rootJoint {
            jointQueue.append(root)
        }
        
        while jointQueue.count > 0 {
            let joint = jointQueue.removeFirst()
            print(joint.description)
            jointQueue.append(contentsOf: joint.childrenJoints)
        }
    }
//
//    func isEquivalent(to other: RKJointTree) -> Bool {
//        guard let rootJoint = self.rootJoint, let otherRootJoint = other.rootJoint else {
//            return false
//        }
//
//        if treeSize != other.treeSize {
//            return false
//        }
//
//        // Compare the structure between two trees
//        return rootJoint.isEquivalent(to: otherRootJoint)
//    }
    
}
