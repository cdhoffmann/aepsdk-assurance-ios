//
//  ContentView.swift
//  TestAppVisionPro
//
//  Created by Christopher Hoffmann on 8/26/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AEPAssurance
import AEPEdge

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            //Model3D(named: "Scene", bundle: realityKitContentBundle)
            //    .padding(.bottom, 50)
            
            Text("Hello, world!")
            Button(action: {
                let event: ExperienceEvent = ExperienceEvent(xdm: ["test": "testValue"])
                Edge.sendEvent(experienceEvent: event)
            }, label: {
                Text("Send Edge Event")
            })
//            Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
//                .font(.title)
//                .frame(width: 360)
//                .padding(24)
//                .glassBackgroundEffect()
        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }.onOpenURL(perform: { incomingURL in
            Assurance.startSession(url: incomingURL)
        })
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
