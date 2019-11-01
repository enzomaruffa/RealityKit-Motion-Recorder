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
    
    var shouldUpdateTree = true
    
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
        
        timerUpdater = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (_) in
            shouldUpdateTree = true
        })
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
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
            
            if shouldUpdateTree {
                if let character = self.character, let characterTree = self.characterTree {
                    
                    shouldUpdateTree = false
                    
                    let jointModelTransforms = bodyAnchor.skeleton.jointModelTransforms.map( { Transform(matrix: $0) })
                    let jointNames = character.jointNames
                    
                    let joints = Array(zip(jointNames, jointModelTransforms))
                    
                    characterTree.updateJoints(from: joints, usingAbsoluteTranslation: true)

                }
            }
            
        }
    }

    fileprivate func saveInDocument(_ title: String, _ text: String) {
        // save tree in document
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(title)
            
            print(fileURL)
            
            //writing
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    fileprivate func createAlert(_ jsonString: String) {
        // open alert asking name
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Nome da posição", message: "Qual o título do documento?", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = "Texto base"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
            
            print("Title: \(textField.text)")
            
            guard textField.text!.count > 0 else  {
                return
            }
            self.saveInDocument(textField.text!, jsonString)
            
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func recordPosition(_ sender: Any) {
        
        if let characterTree = self.characterTree {
            self.recordButton.isEnabled = false
            self.recordButton.alpha = 0.1
                
            characterTree.canUpdate = false
            
            let immutableTree = RKImmutableJointTree(from: characterTree)
            
            // get tree positions
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            do {
                let jsonData = try encoder.encode(immutableTree)

                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("JSON: \(jsonString)")

                    self.createAlert(jsonString)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            self.recordButton.isEnabled = true
            self.recordButton.alpha = 1
            
            characterTree.canUpdate = true
        }
        
    }
    
}
