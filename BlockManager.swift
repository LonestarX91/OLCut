//
//  BlockPlacer.swift
//  OLCut
//
//  Created by Daniel on 04.11.2023.
//

import SceneKit

struct Block {
    var id: Int = 0
    var width: CGFloat
    var height: CGFloat
    var depth: CGFloat
    var position: CGPoint?
    
    func toSceneNode() -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: depth, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
        geometry.materials = [material]
        let node = SCNNode(geometry: geometry)
        return node
    }
}

class Layer {
    var id: Int
    var blocks: [Block] = []
    var depth: CGFloat
    var freeSpaces: [CGRect]
    
    init(id: Int, containerWidth: CGFloat, containerHeight: CGFloat, depth: CGFloat) {
        self.id = id
        self.depth = depth
        // Initially, the entire area of the container is free.
        self.freeSpaces = [CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight)]
    }
    
    func addBlock(_ block: Block, containerWidth: CGFloat, containerHeight: CGFloat) -> Bool {
        // The first block defines the layer's depth
        if blocks.isEmpty {
            depth = block.depth
        } else if block.depth > depth {
            // If the block's depth is greater than the layer's depth, it cannot be added
            return false
        }
        
        for (index, space) in freeSpaces.enumerated().reversed() {
            // Check if the block fits in the current space
            if block.width <= space.width && block.height <= space.height {
                let newPosition = CGPoint(x: space.minX, y: space.minY)
                blocks.append(Block(id: blocks.count, width: block.width, height: block.height, depth: block.depth, position: newPosition))
                
                // Update the free space list considering the block placement
                updateFreeSpaces(block: block, spaceIndex: index)
                return true
            }
        }
        
        // No fitting space found for the block
        return false
    }
    
    private func updateFreeSpaces(block: Block, spaceIndex: Int) {
        let occupiedSpace = freeSpaces[spaceIndex]
        freeSpaces.remove(at: spaceIndex)
        
        // Create new free space to the right of the placed block
        if occupiedSpace.width > block.width + occupiedSpace.minX {
            let newSpaceRight = CGRect(
                x: occupiedSpace.minX + block.width,
                y: occupiedSpace.minY,
                width: occupiedSpace.width - block.width,
                height: block.height)
            freeSpaces.append(newSpaceRight)
        }
        
        // Create new free space above the placed block
        if occupiedSpace.height > block.height + occupiedSpace.minY {
            let newSpaceTop = CGRect(
                x: occupiedSpace.minX,
                y: occupiedSpace.minY + block.height,
                width: occupiedSpace.width,
                height: occupiedSpace.height - block.height
            )
            freeSpaces.append(newSpaceTop)
        }
        
        // Sort the free spaces by their minY, then minX
        freeSpaces.sort { $0.minY < $1.minY || ($0.minY == $1.minY && $0.minX < $1.minX) }
    }
}

class Container {
    var layers: [Layer] = []
    var width: CGFloat
    var height: CGFloat
    var depth: CGFloat
    
    init(width: CGFloat, height: CGFloat, depth: CGFloat) {
        self.width = width
        self.height = height
        self.depth = depth
    }
    
    func addBlock(_ block: Block) {
        // Check existing layers from the front (z=0) towards the back (negative z)
        for layer in layers {
            if layer.addBlock(block, containerWidth: width, containerHeight: height) {
                return  // Block added successfully
            }
        }
        // If the block didn't fit in any existing layer, try to create a new layer
        let newLayer = Layer(id: layers.count, containerWidth: width, containerHeight: height, depth: block.depth)
        if newLayer.addBlock(block, containerWidth: width, containerHeight: height) {
            layers.append(newLayer)
        } else {
            print("Block could not be added to a new layer")
        }
    }
    
    func toSceneNode() -> SCNNode {
        let containerNode = SCNNode()
        
        let offsetX = width / 2
        let offsetY = height / 2
        var offsetZ = 0.0
        for layer in layers {
            print("Layer \(layer.id):")
            for block in layer.blocks {
                print(block)
                let blockNode = block.toSceneNode()
                blockNode.position = SCNVector3(
                    x: Float(block.position?.x ?? 0) + Float(block.width/2),
                    y: Float(block.position?.y ?? 0) + Float(block.height/2),
                    z: -Float(block.depth/2) + Float(offsetZ)
                )
                containerNode.addChildNode(blockNode)
            }
            offsetZ -= layer.depth
        }
        
        // Create the container geometry and make it semi-transparent
        let containerGeometry = SCNBox(width: width, height: height, length: depth, chamferRadius: 0)
        let containerMaterial = SCNMaterial()
        containerMaterial.transparency = 0.5
        containerMaterial.diffuse.contents = UIColor.gray
        containerGeometry.materials = [containerMaterial]
        
        let containerBoxNode = SCNNode(geometry: containerGeometry)
        containerBoxNode.position = SCNVector3(width/2, height/2, -CGFloat(depth/2)) // Centered on X and Y, adjusted for Z
        containerNode.addChildNode(containerBoxNode)
        
        return containerNode
    }
}
