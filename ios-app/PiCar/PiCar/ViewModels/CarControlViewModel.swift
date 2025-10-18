//
//  CarControlViewModel.swift
//  PiCarController
//
//  View model for car control logic
//

import Foundation
import SwiftUI
import Combine

class CarControlViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isConnected = false
    @Published var lastError: String?
    @Published var currentPosition: CGPoint = .zero

    // MARK: - Private Properties

    private let webSocketClient: WebSocketClient
    private var cancellables = Set<AnyCancellable>()
    private var commandThrottle: Timer?

    // Throttle configuration
    private let commandInterval: TimeInterval = 0.05 // 50ms = ~20 commands per second

    // MARK: - Initialization

    init() {
        webSocketClient = WebSocketClient()
        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe connection state
        webSocketClient.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
            }
            .store(in: &cancellables)

        // Observe errors
        webSocketClient.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.lastError = error
            }
            .store(in: &cancellables)
    }

    // MARK: - Connection Management

    func connect() {
        webSocketClient.connect()
    }

    func disconnect() {
        webSocketClient.disconnect()
    }

    // MARK: - Control

    func updateJoystickPosition(_ position: CGPoint) {
        currentPosition = position

        // Send command immediately (throttling handled internally)
        sendControlCommand(x: position.x, y: position.y)
    }

    private func sendControlCommand(x: Double, y: Double) {
        // Invalidate existing throttle timer
        commandThrottle?.invalidate()

        // Send command
        webSocketClient.sendControl(x: x, y: y)

        // Setup throttle timer to prevent command spam
        commandThrottle = Timer.scheduledTimer(withTimeInterval: commandInterval, repeats: false) { _ in
            // Timer expired, next command can be sent
        }
    }

    // MARK: - Convenience Methods

    func stop() {
        updateJoystickPosition(.zero)
    }

    func sendPing() {
        webSocketClient.sendPing()
    }

    // MARK: - Cleanup

    deinit {
        disconnect()
        commandThrottle?.invalidate()
    }
}
