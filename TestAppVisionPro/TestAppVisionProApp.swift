//
//  TestAppVisionProApp.swift
//  TestAppVisionPro
//
//  Created by Christopher Hoffmann on 8/26/24.
//
//
//  Test_VisionProApp.swift
//  Test_VisionPro
//
//  Created by Christopher Hoffmann on 8/26/24.
//  Copyright © 2024 Adobe. All rights reserved.
//

import SwiftUI
import AEPCore
import AEPServices
import AEPLifecycle
import AEPSignal
import AEPIdentity
import AEPAssurance
import AEPEdge

@main
struct TestAppVisionProApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions([Identity.self, Lifecycle.self, Assurance.self]) {
            MobileCore.configureWith(appId: "94f571f308d5/f986c2be4925/launch-e96cdeaddea9-development")
            //Assurance.startSession()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.onChange(of: scenePhase) { oldValue, newValue in
            switch newValue {
            case .active:
                MobileCore.lifecycleStart(additionalContextData: nil)
            case .background:
                MobileCore.lifecyclePause()
            case .inactive:
                print("Inactive scene phase")
            @unknown default:
                print("Unknown scene phase")
            }
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
