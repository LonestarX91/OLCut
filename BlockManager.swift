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
    
    func occupies(rect: CGRect) -> Bool {
            guard let position = self.position else { return false }
            let blockRect = CGRect(x: position.x, y: position.y, width: self.width, height: self.height)
            return rect.contains(blockRect)
        }
    
    var frame: CGRect {
            guard let position = position else { return CGRect.zero }
            return CGRect(x: position.x, y: position.y, width: width, height: height)
        }
}

class Layer {
    var id: Int
    var blocks: [Block] = []
    var depth: CGFloat
    var freeSpaces: [CGRect]
    var containerWidth: CGFloat
    var containerHeight: CGFloat
    init(id: Int, containerWidth: CGFloat, containerHeight: CGFloat, depth: CGFloat) {
        self.id = id
        self.depth = depth
        // Initially, the entire area of the container is free.
        self.containerWidth = containerWidth
        self.containerHeight = containerHeight
        self.freeSpaces = [CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight)]
    }
    
    func addBlock(_ block: Block, containerWidth: CGFloat, containerHeight: CGFloat) -> Bool {
           if blocks.isEmpty {
               if block.width <= containerWidth && block.height <= containerHeight {
                   depth = block.depth
                   let newPosition = CGPoint(x: 0, y: 0) // Place the block at the origin
                   blocks.append(Block(id: blocks.count, width: block.width, height: block.height, depth: block.depth, position: newPosition))
                   updateFreeSpaces(block: block, spaceIndex: 0)
                   return true
               } else {
                   return false
               }
           }

           for existingBlock in blocks {
               // Try to place the block to the right without rotation
               if let newPositionRight = positionToTheRight(of: existingBlock, forNewBlock: block, containerWidth: containerWidth) {
                   blocks.append(Block(id: blocks.count, width: block.width, height: block.height, depth: block.depth, position: newPositionRight))
                   updateFreeSpacesAfterPlacement(block: block)
                   return true
               }

               // Try to place the block to the right with rotation
               let rotatedBlock = Block(id: block.id, width: block.height, height: block.width, depth: block.depth)
               if let newPositionRightRotated = positionToTheRight(of: existingBlock, forNewBlock: rotatedBlock, containerWidth: containerWidth) {
                   blocks.append(Block(id: blocks.count, width: rotatedBlock.width, height: rotatedBlock.height, depth: rotatedBlock.depth, position: newPositionRightRotated))
                   updateFreeSpacesAfterPlacement(block: rotatedBlock)
                   return true
               }

               // Try to place the block above without rotation
               if let newPositionAbove = positionAbove(of: existingBlock, forNewBlock: block, containerHeight: containerHeight) {
                   blocks.append(Block(id: blocks.count, width: block.width, height: block.height, depth: block.depth, position: newPositionAbove))
                   updateFreeSpacesAfterPlacement(block: block)
                   return true
               }

               // Try to place the block above with rotation
               if let newPositionAboveRotated = positionAbove(of: existingBlock, forNewBlock: rotatedBlock, containerHeight: containerHeight) {
                   blocks.append(Block(id: blocks.count, width: rotatedBlock.width, height: rotatedBlock.height, depth: rotatedBlock.depth, position: newPositionAboveRotated))
                   updateFreeSpacesAfterPlacement(block: rotatedBlock)
                   return true
               }
           }

           // No fitting space found for the block in any orientation or position
           return false
       }
    
    private func updateFreeSpaces(block: Block, spaceIndex: Int) {
            // Initial placement assumes the whole layer is free space.
            freeSpaces.removeAll()
            
            // Calculate the remaining free space after placing the block.
            let blockFrame = CGRect(x: 0, y: 0, width: block.width, height: block.height)

            // Create new free spaces to the right and above the placed block.
            let spaceRight = CGRect(x: blockFrame.maxX, y: 0, width: self.depth - blockFrame.maxX, height: containerHeight)
            if spaceRight.width > 0 {
                freeSpaces.append(spaceRight)
            }

            let spaceAbove = CGRect(x: 0, y: blockFrame.maxY, width: containerWidth, height: containerHeight - blockFrame.maxY)
            if spaceAbove.height > 0 {
                freeSpaces.append(spaceAbove)
            }
        }
    
    private func positionToTheRight(of existingBlock: Block, forNewBlock newBlock: Block, containerWidth: CGFloat) -> CGPoint? {
            let potentialX = existingBlock.position!.x + existingBlock.width
            if potentialX + newBlock.width <= containerWidth {
                // Check if the vertical space is also free
                let potentialSpace = CGRect(x: potentialX, y: existingBlock.position!.y, width: newBlock.width, height: newBlock.height)
                if isSpaceFree(potentialSpace) {
                    return CGPoint(x: potentialX, y: existingBlock.position!.y)
                }
            }
            return nil
        }
    
    private func positionAbove(of existingBlock: Block, forNewBlock newBlock: Block, containerHeight: CGFloat) -> CGPoint? {
            let potentialY = existingBlock.position!.y + existingBlock.height
            if potentialY + newBlock.height <= containerHeight {
                // Check if the horizontal space is also free
                let potentialSpace = CGRect(x: existingBlock.position!.x, y: potentialY, width: newBlock.width, height: newBlock.height)
                if isSpaceFree(potentialSpace) {
                    return CGPoint(x: existingBlock.position!.x, y: potentialY)
                }
            }
            return nil
        }
    
    private func isSpaceFree(_ space: CGRect) -> Bool {
            for block in blocks {
                let blockFrame = CGRect(x: block.position!.x, y: block.position!.y, width: block.width, height: block.height)
                if space.intersects(blockFrame) {
                    return false
                }
            }
            return true
        }
    
    private func updateFreeSpaces(afterPlacing block: Block, in occupiedSpace: CGRect) {
            // Calculate the remaining space to the right of the placed block.
            if occupiedSpace.maxX > block.position!.x + block.width {
                let spaceRight = CGRect(x: block.position!.x + block.width, y: block.position!.y,
                                        width: occupiedSpace.maxX - (block.position!.x + block.width), height: occupiedSpace.height)
                freeSpaces.append(spaceRight)
            }

            // Calculate the remaining space above the placed block.
            if occupiedSpace.maxY > block.position!.y + block.height {
                let spaceAbove = CGRect(x: block.position!.x, y: block.position!.y + block.height,
                                        width: occupiedSpace.width, height: occupiedSpace.maxY - (block.position!.y + block.height))
                freeSpaces.append(spaceAbove)
            }

            // Remove the occupied space.
            freeSpaces = freeSpaces.filter { !block.frame.intersects($0) }
        }
    
    private func findPositionForBlock(_ block: Block, in combinedSpace: CGRect) -> CGPoint? {
            // This is a simplified version. The actual implementation should consider all free spaces and their arrangement.
            for space in freeSpaces {
                if block.width <= space.width && block.height <= space.height {
                    return CGPoint(x: space.minX, y: space.minY)
                }
            }
            return nil
        }

        private func combinedFreeSpace() -> CGRect {
            // Combine all free spaces into one CGRect representing the total free area.
            // This is a naive implementation; the actual implementation may need to consider complex shapes and could be non-rectangular.
            return freeSpaces.reduce(CGRect.zero) { (result, space) -> CGRect in
                return result.union(space)
            }
        }

    private func updateFreeSpacesAfterPlacement(block: Block) {
            // After placing a block, we need to update the list of free spaces.
            // This is a complex task as it involves subtracting the block's space from the combined free space
            // and potentially dividing existing spaces into smaller ones.
            
            // This code is a placeholder. Implementing the full logic will require a more complex spatial partitioning system.
            // For now, we can remove any space that is fully occupied by the placed block
            freeSpaces = freeSpaces.filter { !block.occupies(rect: $0) }
            
            // Then, add logic to split or reduce the size of partially occupied spaces.
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
