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

extension AssuranceSession: SocketEventListener {
    
    func webSocket(_ socket: SocketConnectable, didReceiveEvent event: AssuranceEvent) {
        Log.trace(label: AssuranceConstants.LOG_TAG, "Received event from assurance session - \(event.description)")
        guard let controlType = event.commandType else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "A non control event is received event from assurance session. Ignoring to process event - \(event.description)")
            return
        }

        if AssuranceConstants.CommandType.START_EVENT_FORWARDING == controlType {
            canStartForwarding = true
            // On reception of the startForwarding event
            // 1. Remove the WebView UI and display the floating button
            // 2. Share the Assurance shared state
            // 3. Notify the client plugins on successful connection
            pinCodeScreen?.connectionSucceeded()
            statusUI.display()
            statusUI.updateForSocketConnected()
            pluginHub.notifyPluginsOnConnect()
            outboundSource.add(data: 1)
            return
        }

        // add the incoming event to inboundQueue and process them
        inboundQueue.enqueue(newElement: event)
        inboundSource.add(data: 1)
    }

    func webSocketDidConnect(_ socket: SocketConnectable) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance session successfully connected.")
        self.sendClientInfoEvent()
    }

    func webSocketDidDisconnectConnect(_ socket: SocketConnectable, _ closeCode: Int, _ reason: String, _ wasClean: Bool) {

        // this will happen when user disconnects hitting the disconnect button in Status UI
        // notify plugin on normal closure
        if closeCode == AssuranceConstants.SocketCloseCode.NORMAL_CLOSURE {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Socket disconnected successfully with close code \(closeCode). Normal closure of websocket.")
            pinCodeScreen?.connectionFinished()
            statusUI.updateForSocketDisconnected()
            pluginHub.notifyPluginsOnDisconnect(withCloseCode: closeCode)
        }

            // Close code 4900, happens when there is an orgId mismatch
            // This is a non-retry error. Display the error back to user and close the connection.
        else if closeCode == AssuranceConstants.SocketCloseCode.ORG_MISMATCH {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Socket disconnected with close code \(closeCode). OrgID Mismatch.")
            displaySocketErrorMessage(error: AssuranceSocketError.ORGID_MISMATCH, closeCode: closeCode)
        }

            // Close code 4901, happens when the number of connections per session exceeds the limit
            // Configurable value and its default value is 200
            // This is a non-retry error. Display the error back to user and close the connection.
        else if closeCode == AssuranceConstants.SocketCloseCode.CONNECTION_LIMIT {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Socket disconnected with close code \(closeCode). Connection Limit reached (200 devices per session).")
            displaySocketErrorMessage(error: AssuranceSocketError.CONNECTION_LIMIT, closeCode: closeCode)
        }

            // Close code 4902, happens when the clients exceeds the number of Griffon events that can be sent per minute
            // Configurable value : default value is 10k events per minute
            // This is a non-retry error. Display the error back to user and close the connection.
        else if closeCode == AssuranceConstants.SocketCloseCode.EVENTS_LIMIT {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Socket disconnected with close code \(closeCode). Event Limit reached å(10k events per minute for a client).")
            displaySocketErrorMessage(error: AssuranceSocketError.EVENT_LIMIT, closeCode: closeCode)
        }

            // Close code 4400, happens when there is a something wrong with the client during socket connection.
            // This error is generically thrown if the client doesn't adhere to the rules of the socket connection.
            // Example:
            // If clientInfoEvent is not the first event to socket
            // If there are any missing parameters in the socket URL
        else if closeCode == AssuranceConstants.SocketCloseCode.CLIENT_ERROR {
            displaySocketErrorMessage(error: AssuranceSocketError.CLIENT_ERROR, closeCode: closeCode)
        }

            // for all other abnormal closures, display error back to UI and attempt to reconnect
        else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Abnormal closure of webSocket. Reason - \(reason) and closeCode - \(closeCode)")

            // do the reconnect logic only if session is already connected
            guard let _ = assuranceExtension.sessionId else {
                return
            }

            // immediately attempt to reconnect if the disconnect happens for the first time
            // then forth make an reconnect attempt every 5 seconds
            Log.debug(label: AssuranceConstants.LOG_TAG, "Attempting to reconnect....")
            let delayBeforeReconnect = isAttemptingToReconnect ? RECONNECT_TIMEOUT : 0

            // If the disconnect happens because of abnormal close code. And if we are attempting to reconnect for the first time then,
            // 1. Make an appropriate UI log.
            // 2. Change the button graphics to gray out.
            // 3. Notify plugins on disconnect with abnormal close code.
            // 4. Attempt to reconnect with appropriate time delay.
            if !isAttemptingToReconnect {
                isAttemptingToReconnect = true
                canStartForwarding = false //set this to false so that all the events are held up until client event is sent after successful reconnect
                statusUI.updateForSocketInActive()
                pluginHub.notifyPluginsOnDisconnect(withCloseCode: closeCode)
            }

            let delay = DispatchTimeInterval.seconds(delayBeforeReconnect)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.startSession()
            }
        }
    }

    func webSocketOnError(_ socket: SocketConnectable) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "AssuranceSession: webSocketOnError is called. Error occurred during socket connection.")
    }

    func webSocket(_ socket: SocketConnectable, didChangeState state: SocketState) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "AssuranceSession: Socket state changed \(socket.socketState)")
    }

    private func displaySocketErrorMessage(error: AssuranceSocketError, closeCode: Int) {

    }
}
