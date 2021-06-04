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

import Foundation
import AEPServices

extension AssuranceSession {
    
    func sendEvent(_ assuranceEvent: AssuranceEvent) {
        outboundQueue.enqueue(newElement: assuranceEvent)
        outboundSource.add(data: 1)
    }
    
    func sendClientInfoEvent() {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Sending client info event to Assurance")
        let clientEvent = AssuranceEvent.init(type: AssuranceConstants.EventType.CLIENT, payload: AssuranceClientInfo.getData())
        self.socket.sendEvent(clientEvent)
    }
    
    func handleOutBoundEvents() {
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
    
    
    func handleInBoundEvents() {
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
    
}
