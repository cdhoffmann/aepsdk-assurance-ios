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
        if #available(iOS 13.0, *) {
            return NativeSocket(withListener: self)
        } else {
            return WebViewSocket(withListener: self)
        }
    }()
    
    lazy var statusUI: iOSStatusUI  = {
        iOSStatusUI.init(withSession: self)
    }()
    
    
    /// Initializer with instance of  `Assurance` extension
    init(_ assuranceExtension: Assurance) {
        self.assuranceExtension = assuranceExtension
        handleInBoundEvents()
        handleOutBoundEvents()
    }

    /// Called when a valid assurance deeplink url is received from the startSession API
    /// Calling this method will attempt to display the pincode screen for session authentication
    ///
    /// Thread : Listener thread from EventHub
    func startSession() {
        registerInternalPlugins()
        
        if let socketURL = assuranceExtension.socketURL {
            self.statusUI.display()
            socket.connect(withUrl: URL(string: socketURL)!)
            return
        }
        
        let pinCodeScreen = iOSPinCodeScreen.init(withExtension: assuranceExtension)
        self.pinCodeScreen = pinCodeScreen

        pinCodeScreen.getSocketURL(callback: { [weak self]  socketUrl, error in
            // Thread : main thread (this callback is called from `overrideUrlLoad` method of WKWebView)
            Log.debug(label: AssuranceConstants.LOG_TAG, "Attempting to make a socket connection with URL : \(socketUrl)")
            self?.assuranceExtension.socketURL = socketUrl.absoluteString
            self?.socket.connect(withUrl: socketUrl)
            pinCodeScreen.connectionInitialized()
        })

    }

    func sendEvent(_ assuranceEvent: AssuranceEvent) {
        outboundQueue.enqueue(newElement: assuranceEvent)
        outboundSource.add(data: 1)
    }
    
    func sendClientInfoEvent() {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Sending client info event to Assurance")
        let clientEvent = AssuranceEvent.init(type: AssuranceConstants.EventType.CLIENT, payload: AssuranceClientInfo.getData())
        self.socket.sendEvent(clientEvent)
    }
    
    func terminateSession() {
        socket.disconnect()
        clearSessionData()
        assuranceExtension.clearState()
    }
    
    func addClientLog(_ message: String, visibility: AssuranceClientLogVisibility) {
        statusUI.addClientLog(message, visibility: visibility)
    }
    
    func clearSessionData() {
        canStartForwarding = false
        assuranceExtension.sessionId = nil
        assuranceExtension.socketURL = nil
        assuranceExtension.environment = AssuranceConstants.DEFAULT_ENVIRONMENT
        pinCodeScreen = nil
    }
    
    
    // MARK: - Private methods
    
    private func handleOutBoundEvents() {
        outboundSource.setEventHandler(handler: {
            if SocketState.OPEN != self.socket.socketState {
                Log.trace(label: AssuranceConstants.LOG_TAG, "Queuing event before connection has been initialized(waiting for deep link to initialize connection with pin code entry)")
                return
            }

            if !self.canStartForwarding {
                Log.trace(label: AssuranceConstants.LOG_TAG, "Assurance Extension hasn't received startForwarding control event to start sending the queued events.")
                return
            }

            while self.outboundQueue.size() >= 0 {
                let event = self.outboundQueue.dequeue()
                if let event = event {
                    self.socket.sendEvent(event)
                }
            }
        })
        outboundSource.resume()
    }
    
    
    private func handleInBoundEvents() {
        inboundSource.setEventHandler(handler: {
            while self.inboundQueue.size() >= 0 {
                let event = self.inboundQueue.dequeue()
                if let event = event {
                    self.pluginHub.notifyPluginsOfEvent(event)
                }
            }
        })
        inboundSource.resume()
    }
    
    private func registerInternalPlugins() {
        pluginHub.registerPlugin(PluginFakeEvent(), toSession: self)
        pluginHub.registerPlugin(PluginConfigModify(), toSession: self)
        pluginHub.registerPlugin(PluginScreenshot(), toSession: self)
    }

}
