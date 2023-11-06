//
//  ContentView.swift
//  OLCut
//
//  Created by Daniel on 04.11.2023.
//

import SwiftUI
import SceneKit

struct ContentView: View {
    @State private var containerWidth: String = "202"
    @State private var containerHeight: String = "120"
    @State private var containerDepth: String = "202"
    @State private var blockWidth: String = ""
    @State private var blockHeight: String = ""
    @State private var blockThickness: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Container Dimensions")) {
                    TextField("Width", text: $containerWidth)
                    TextField("Height", text: $containerHeight)
                    TextField("Height", text: $containerDepth)
                    
                }
                Section(header: Text("Block Dimensions")) {
                    TextField("Width", text: $blockWidth)
                    TextField("Height", text: $blockHeight)
                    TextField("Thickness", text: $blockThickness)
                    Button("Add Block") {  }
                }
                Section {
                    Button("Calculate Layout") {  }
                }
                Section(header: Text("Blocks")) {
//                    List(blocks, id: \.self) { block in
//                        Text("Block: \(block.width) x \(block.height)")
//                    }
                }
            }
            .navigationBarTitle("Layering App")
            SceneKitView()
        }
    }
    
}
