//
//  ContainerView.swift
//  OLCut
//
//  Created by Daniel on 04.11.2023.
//

import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    init() {
        print("init")
        blocks = blocks.sorted {
            if $0.depth == $1.depth {
                return ($0.width * $0.height) > ($1.width * $1.height)
            } else {
                return $0.depth > $1.depth
            }
        }
        for block in blocks {
            container.addBlock(block)
        }
    }
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = makeScene() // Re-create the scene with the updated blocks
    }
    
    var container = Container(width: 202, height: 120, depth: 202)
    var blocks: [Block] = [
        Block(width: 180, height: 77, depth: 12),
        Block(width: 77, height: 75, depth: 12),
        Block(width: 120, height: 76, depth: 12),
        Block(width: 30, height: 22, depth: 8),
        Block(width: 90, height: 22, depth: 10)
    ]

    func makeUIView(context: Context) -> SCNView {

        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true // Allows user to manipulate camera
        sceneView.autoenablesDefaultLighting = true // Adds default lighting
        sceneView.backgroundColor = UIColor.white
        return sceneView
    }
    
    private func makeScene() -> SCNScene {
        print("make scene")
        let scene = SCNScene()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: Float(container.width/2), y: Float(container.height/2), z: Float(container.depth*2.2))
        cameraNode.camera?.zFar = 1000
        scene.rootNode.addChildNode(cameraNode)
        
//        let containerGeometry = SCNBox(width: containerWidth/2, height: containerHeight/2, length: -containerDepth/2, chamferRadius: 0)
//        let containerMaterial = SCNMaterial()
//        containerMaterial.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.5)
//        containerGeometry.materials = [containerMaterial]
//        
//        let containerNode = SCNNode(geometry: containerGeometry)
//        containerNode.position = SCNVector3(x: Float(containerWidth/2), y: Float(containerHeight/2), z: -Float(containerDepth/2))
//        scene.rootNode.addChildNode(containerNode)
        
        
        let containerNode = container.toSceneNode()
        scene.rootNode.addChildNode(containerNode)


        let outlineGeometry = SCNBox(width: CGFloat(container.width) + 0.1, height: CGFloat(container.height) + 0.1, length: container.depth + 0.1, chamferRadius: 0)
        let outlineMaterial = SCNMaterial()
        outlineMaterial.diffuse.contents = UIColor.green
        outlineMaterial.isDoubleSided = true
        outlineMaterial.fillMode = .lines
        outlineGeometry.materials = [outlineMaterial]
        
        let outlineNode = SCNNode(geometry: outlineGeometry)
        outlineNode.position = SCNVector3(x: Float(container.width/2), y: Float(container.height / 2), z: -Float(container.depth / 2))
        scene.rootNode.addChildNode(outlineNode)


        let originMarker = SCNSphere(radius: 5)
        let originNode = SCNNode(geometry: originMarker)
        originNode.position = SCNVector3(0, 0, 0)
        originNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        scene.rootNode.addChildNode(originNode)
        return scene
    }
}

