//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

class MockWebSocketServer {
    
    enum Error: Swift.Error {
        case portOccupied
    }
    
    let portNumber = UInt16.random(in: 49152..<65535)
    var connections = [NWConnection]()
    var listener: NWListener?
    static var messageHandler: ((Data?) -> Data?)?
    
    private static func recursiveRead(_ connection: NWConnection) {
        connection.receiveMessage { content, contentContext, _, error in
            if let error {
                print("Connection failed to receive message, error: \(error)")
                return
            }
            
            if let content, let contentContext {
                if let processedMessage = Self.messageHandler?(content) {
                    connection.send(
                        content: processedMessage,
                        contentContext: contentContext,
                        completion: .idempotent)
                }
            }
            
            recursiveRead(connection)
        }
    }
    
    func start() throws -> URL  {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        let stack = params.defaultProtocolStack
        let ws = NWProtocolWebSocket.Options()
        stack.applicationProtocols.insert(ws, at: 0)
        let port = NWEndpoint.Port(rawValue: portNumber)!
        guard let listener = try? NWListener(using: params, on: port) else {
            throw Error.portOccupied
        }
        
        // set event handlers
        listener.newConnectionHandler = { [weak self] conn in
            self?.connections.append(conn)
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Connection is ready")
                case .setup:
                    print("Connection is setup")
                case .preparing:
                    print("Connection is preparing")
                case .waiting(let error):
                    print("Connection is waiting with error: \(error)")
                case .failed(let error):
                    print("Connection failed with error \(error)")
                case .cancelled:
                    print("Connection is cancelled")
                @unknown default:
                    print("Connection is in unknown state -> \(state)")
                }
            }
            conn.start(queue: DispatchQueue.global(qos: .userInitiated))
            Self.recursiveRead(conn)
        }
        
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Socket is ready")
            case .setup:
                print("Socket is setup")
            case .cancelled:
                print("Socket is cancelled")
            case .failed(let error):
                print("Socket failed with error: \(error)")
            case .waiting(let error):
                print("Socket in waiting state with error: \(error)")
            @unknown default:
                print("Socket in unkown state: \(state)")
                break
            }
        }
        
        // start the listener
        listener.start(queue: DispatchQueue.global(qos: .userInitiated))
        self.listener = listener
        return URL(string: "http://localhost:\(portNumber)/event/realtime")!
    }
    
    func stop() {
        self.listener?.cancel()
    }
    
    func sendTransientFailureToConnections(closeCode: NWProtocolWebSocket.CloseCode.Defined) {
        self.connections.forEach {
            let metadata = NWProtocolWebSocket.Metadata(opcode: .close)
            metadata.closeCode = .protocolCode(closeCode)
            $0.send(
                content: nil,
                contentContext: NWConnection.ContentContext(identifier: "WebSocket", metadata: [metadata]),
                completion: .idempotent
            )
        }
    }
    
    func sendData(data: Data) {
        let message = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(
            identifier: "send",
            metadata: [message])
        self.connections.forEach {
            $0.send(
                content: data,
                contentContext: context,
                completion: .contentProcessed { error in
                    if let error {
                        print("Failed to send data, error: \(error)")
                        return
                    }
                    
                    print("Data was sent")
                })
        }
    }
}
