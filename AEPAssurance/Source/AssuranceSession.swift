/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPServices
import Foundation

class AssuranceSession {
    let RECONNECT_TIMEOUT = 5
    let assuranceExtension: Assurance
    var pinCodeScreen: SessionAuthorizable?
    let outboundQueue: ThreadSafeQueue = ThreadSafeQueue<AssuranceEvent>(withLimit: 200)
    let inboundQueue: ThreadSafeQueue = ThreadSafeQueue<AssuranceEvent>(withLimit: 200)
    let inboundSource = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.global(qos: .default))
    let outboundSource = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.global(qos: .default))
    let pluginHub: PluginHub = PluginHub()
    
    // MARK:- boolean flags
    /// indicates if the session is currently attempting to reconnect. This flag is set when the session disconnects due to some retry-able reason,
    /// This flag is reset when the session is connected
    var isAttemptingToReconnect: Bool = false
    
    /// indicates if Assurance SDK can start forwarding events to the session. This flag is set when a command  `startForwarding` is received from the socket.
    var canStartForwarding: Bool = false
    
    
    lazy var socket: SocketConnectable  = {
            return WebViewSocket(withListener: self)
    }()
    
//    lazy var socket: SocketConnectable  = {
//        if #available(iOS 13.0, *) {
//            return NativeSocket(withListener: self)
//        } else {
//            return WebViewSocket(withListener: self)
//        }
//    }()
    
    lazy var statusUI: iOSStatusUI  = {
        iOSStatusUI.init(withSession: self)
    }()
    
    
    /// Initializer with instance of  `Assurance` extension
    init(_ assuranceExtension: Assurance) {
        self.assuranceExtension = assuranceExtension
        handleInBoundEvents()
        handleOutBoundEvents()
        registerInternalPlugins()
    }

    /// Called when a valid assurance deeplink url is received from the startSession API
    /// Calling this method will attempt to display the pincode screen for session authentication
    ///
    /// Thread : Listener thread from EventHub
    func startSession() {
        
        if (socket.socketState == .OPEN || socket.socketState == .CONNECTING) {
            Log.debug(label: AssuranceConstants.LOG_TAG, "There is already an ongoing Assurance session. Ignoring to start new session.")
            return
        }
        
        // if there is a socket URL already connected in the previous session then reuse it.
        if let socketURL = assuranceExtension.connectedSocketURL {
            self.statusUI.display()
            socket.connect(withUrl: URL(string: socketURL)!)
            return
        }
        
        // if there were no previous connected URL then start a new session
        startNewSession()
    }
    
    func startNewSession() {
        let pinCodeScreen = iOSPinCodeScreen.init(withExtension: assuranceExtension)
        self.pinCodeScreen = pinCodeScreen
        
        // invoke the pinpad screen and create a socketURL with the pincode and other essential parameters
        pinCodeScreen.getSocketURL(callback: { [weak self]  socketUrl, error in
            if let error = error {
                self?.handleConnectionError(error: error, closeCode: nil)
                return
            }
            
            guard let socketUrl = socketUrl else {
                Log.debug(label: AssuranceConstants.LOG_TAG, "SocketURL to connect to session is empty. Ignoring to start Assurance session.")
                return
            }
            
            // Thread : main thread (this callback is called from `overrideUrlLoad` method of WKWebView)
            Log.debug(label: AssuranceConstants.LOG_TAG, "Attempting to make a socket connection with URL : \(socketUrl)")
            self?.socket.connect(withUrl: socketUrl)
            pinCodeScreen.connectionInitialized()
        })
    }

    
    func terminateSession() {
        socket.disconnect()
        clearSessionData()
        assuranceExtension.clearState()
    }
    
    func clearSessionData() {
        canStartForwarding = false
        pluginHub.notifyPluginsOnSessionTerminated()
        assuranceExtension.sessionId = nil
        assuranceExtension.connectedSocketURL = nil
        assuranceExtension.environment = AssuranceConstants.DEFAULT_ENVIRONMENT
        pinCodeScreen = nil
    }
    
    func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        statusUI.addClientLog(message, visibility: visibility)
    }
    
    private func registerInternalPlugins() {
        pluginHub.registerPlugin(PluginFakeEvent(), toSession: self)
        pluginHub.registerPlugin(PluginConfigModify(), toSession: self)
        pluginHub.registerPlugin(PluginScreenshot(), toSession: self)
    }

}
