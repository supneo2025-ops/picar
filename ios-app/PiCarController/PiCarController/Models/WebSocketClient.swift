//
//  WebSocketClient.swift
//  PiCarController
//
//  WebSocket client for communicating with Pi Car server
//

import Foundation
import Combine

class WebSocketClient: NSObject, ObservableObject {
    // MARK: - Configuration

    // Update this IP address to match your Raspberry Pi
    static let PI_SERVER_IP = "192.168.100.148"
    static let PI_SERVER_PORT = 5000

    // MARK: - Published Properties

    @Published var isConnected = false
    @Published var lastError: String?

    // MARK: - Private Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private var handshakeTask: URLSessionDataTask?
    private var urlSession: URLSession?
    private var reconnectTimer: Timer?
    private var shouldReconnect = true
    private var currentSid: String?

    // MARK: - Initialization

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // MARK: - Connection Management

    func connect() {
        disconnect()

        shouldReconnect = true
        initiateHandshake()
    }

    func disconnect() {
        shouldReconnect = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil

        handshakeTask?.cancel()
        handshakeTask = nil
        currentSid = nil

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        DispatchQueue.main.async {
            self.isConnected = false
        }

        print("WebSocket disconnected")
    }

    // MARK: - Message Handling

    func sendControl(x: Double, y: Double) {
        guard webSocketTask != nil else {
            print("WebSocket not connected; skipping control send")
            return
        }

        let message: [String: Any] = [
            "type": "control",
            "x": x,
            "y": y
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to encode control message")
            return
        }

        // Socket.IO protocol: messages are prefixed with message type
        // Type 42 is a message event
        let socketIOMessage = "42[\"control\",\(jsonString)]"

        send(message: socketIOMessage)
    }

    func sendPing() {
        // Socket.IO ping format
        send(message: "2")
    }

    private func send(message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)

        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                print("WebSocket send error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.lastError = error.localizedDescription
                    self?.handleDisconnection()
                }
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving messages
                self.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                    self.handleDisconnection()
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleTextMessage(text)
            }
        @unknown default:
            break
        }
    }

    private func handleTextMessage(_ text: String) {
        // Socket.IO protocol handling
        // Messages are prefixed with packet type:
        // 0 = open, 2 = ping, 3 = pong, 40 = connect, 41 = disconnect, 42 = message

        if text.hasPrefix("0") {
            // Connection acknowledgment
            print("Received connection ack")
            DispatchQueue.main.async {
                self.isConnected = true
            }
            send(message: "40")
        } else if text.hasPrefix("3") {
            // Pong response
            // Connection is alive
        } else if text.hasPrefix("42") {
            // Message event
            // Extract JSON payload after "42"
            let jsonString = String(text.dropFirst(2))
            if let data = jsonString.data(using: .utf8) {
                handleJSONMessage(data)
            }
        }
    }

    private func handleJSONMessage(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Received message: \(json)")

                // Handle different message types
                if let type = json["type"] as? String {
                    switch type {
                    case "status":
                        handleStatusMessage(json)
                    default:
                        break
                    }
                }
            }
        } catch {
            print("Failed to parse JSON message: \(error)")
        }
    }

    private func handleStatusMessage(_ json: [String: Any]) {
        if let connected = json["connected"] as? Bool {
            DispatchQueue.main.async {
                self.isConnected = connected
            }
        }
    }

    private func initiateHandshake() {
        handshakeTask?.cancel()

        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let urlString = "http://\(Self.PI_SERVER_IP):\(Self.PI_SERVER_PORT)/socket.io/?EIO=4&transport=polling&t=\(timestamp)"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.lastError = "Invalid handshake URL" }
            scheduleReconnect()
            return
        }

        print("Starting Socket.IO handshake: \(urlString)")

        handshakeTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Handshake failed: \(error.localizedDescription)")
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
                self.scheduleReconnect()
                return
            }

            guard
                let data = data,
                let payload = String(data: data, encoding: .utf8),
                payload.first == "0",
                let braceIndex = payload.firstIndex(of: "{")
            else {
                print("Unexpected handshake payload")
                DispatchQueue.main.async { self.lastError = "Handshake failed" }
                self.scheduleReconnect()
                return
            }

            let jsonString = String(payload[braceIndex...])

            guard
                let jsonData = jsonString.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                let sid = jsonObject["sid"] as? String
            else {
                print("Failed to parse handshake SID")
                DispatchQueue.main.async { self.lastError = "Handshake parse error" }
                self.scheduleReconnect()
                return
            }

            print("Handshake SID: \(sid)")
            self.currentSid = sid
            self.openWebSocket(with: sid)
        }

        handshakeTask?.resume()
    }

    private func openWebSocket(with sid: String) {
        let urlString = "ws://\(Self.PI_SERVER_IP):\(Self.PI_SERVER_PORT)/socket.io/?EIO=4&transport=websocket&sid=\(sid)"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.lastError = "Invalid WebSocket URL" }
            scheduleReconnect()
            return
        }

        print("Connecting to: \(urlString)")

        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()

        receiveMessage()
    }

    // MARK: - Reconnection

    private func handleDisconnection() {
        DispatchQueue.main.async {
            self.isConnected = false
        }

        if shouldReconnect {
            scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        reconnectTimer?.invalidate()

        print("Scheduling reconnection in 2 seconds...")

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            print("Attempting to reconnect...")
            self?.connect()
        }
    }

    // MARK: - Cleanup

    deinit {
        disconnect()
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                   webSocketTask: URLSessionWebSocketTask,
                   didOpenWithProtocol protocol: String?) {
        print("WebSocket did open")
        DispatchQueue.main.async {
            self.isConnected = true
            self.lastError = nil
        }
    }

    func urlSession(_ session: URLSession,
                   webSocketTask: URLSessionWebSocketTask,
                   didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                   reason: Data?) {
        print("WebSocket did close with code: \(closeCode)")
        handleDisconnection()
    }
}

// MARK: - URLSessionDelegate

extension WebSocketClient: URLSessionDelegate {
    func urlSession(_ session: URLSession,
                   task: URLSessionTask,
                   didCompleteWithError error: Error?) {
        if let error = error {
            print("URLSession task completed with error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
            }
            handleDisconnection()
        }
    }
}
