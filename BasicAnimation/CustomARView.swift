//
//  CustomARView.swift
//  BasicAnimation
//
//  Created by Mark Horgan on 01/06/2022.
//

import ARKit
import RealityKit
import Combine

class CustomARView: ARView {
    private var subscription: AnyCancellable?
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config, options: [])
        
        let boxEntity = ModelEntity(mesh: .generateBox(size: 0.05), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        boxEntity.generateCollisionShapes(recursive: true)
        let anchorEntity = AnchorEntity(plane: .horizontal)
        anchorEntity.addChild(boxEntity)
        scene.addAnchor(anchorEntity)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        addCoaching()
    }
    
    @objc required dynamic init?(coder decorder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .ended {
            let screenLocation = gestureRecognizer.location(in: self)
            let hits = hitTest(screenLocation, query: .nearest)
            if hits.count > 0, let modelEntity = hits[0].entity as? ModelEntity {
                moveBox(modelEntity)
            }
        }
    }
    
    private func moveBox(_ modelEntity: ModelEntity) {
        guard subscription == nil else { return }
        modelEntity.model?.materials = [SimpleMaterial(color: .blue, isMetallic: false)]
        let transform = Transform(scale: .one, rotation: simd_quatf(), translation: randomVector(length: 0.08))
        modelEntity.move(to: transform, relativeTo: modelEntity, duration: 1, timingFunction: .easeInOut)
        subscription = scene.publisher(for: AnimationEvents.PlaybackCompleted.self, on: modelEntity).sink(receiveValue: { [weak self] _ in
            modelEntity.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
            self?.subscription = nil
        })
    }
    
    private func randomVector(length: Float) -> simd_float3 {
        let angle = Float.random(in: -.pi...(.pi))
        return [cos(angle), 0, sin(angle)] * length
    }
    
    private func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
    }
}
