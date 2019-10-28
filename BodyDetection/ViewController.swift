/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    @IBOutlet weak var messageLabel: MessageLabel!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [0.7, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    var characterTree: RKJointTree?
    
    // A tracked raycast which is used to place the character accurately
    // in the scene wherever the user taps.
    var placementRaycast: ARTrackedRaycast?
    var tapPlacementAnchor: AnchorEntity?
    
    var timerUpdater: Timer?
    
    @IBOutlet weak var recordButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            if timerUpdater == nil {
                
                print("Creating timer")
                
                timerUpdater = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { (_) in
                    
                    print("Running timer")
                    
                    if let character = self.character, let characterTree = self.characterTree {
                        
                        let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms.map( { Transform(matrix: $0) })
                        let jointNames = character.jointNames
                        
                        let joints = Array(zip(jointNames, jointModelTransforms))
                        
                        characterTree.updateJoints(from: joints, usingAbsoluteTranslation: true)
                        
//                        characterTree.printJointsBFS()
                        
                    }
                    
                })
                
                timerUpdater?.fire()
            }
            
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
   
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
                
                let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms.map( { Transform(matrix: $0) })
                let jointNames = character.jointNames
                
                let joints = Array(zip(jointNames, jointModelTransforms))
                characterTree = RKJointTree(from: joints, usingAbsoluteTranslation: true)
            }
        }
    }

    @IBAction func recordPosition(_ sender: Any) {
        
        if let characterTree = self.characterTree {
            self.recordButton.isEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // get tree positions
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted

                do {
                    let jsonData = try encoder.encode(characterTree)

                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        print(jsonString)
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
                // open alert asking name
                
                // save tree in document
                
            }
        }
        
    }
    
}
