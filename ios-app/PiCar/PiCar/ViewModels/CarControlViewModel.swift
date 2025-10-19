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
    @Published var leftThrottle: Double = 0.0
    @Published var rightThrottle: Double = 0.0

    // MARK: - Private Properties

    private let webSocketClient: WebSocketClient
    private var cancellables = Set<AnyCancellable>()
    private var lastCommandTime: Date = .distantPast
    private var pendingCommand: (() -> Void)?
    private var throttleTimer: Timer?

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

    func updateLeftThrottle(_ value: Double) {
        leftThrottle = value
        sendDualControlCommand()
    }

    func updateRightThrottle(_ value: Double) {
        rightThrottle = value
        sendDualControlCommand()
    }

    private func sendDualControlCommand() {
        let now = Date()
        let timeSinceLastCommand = now.timeIntervalSince(lastCommandTime)

        if timeSinceLastCommand >= commandInterval {
            // Enough time has passed, send immediately
            executeSendCommand()
            lastCommandTime = now

            // Cancel any pending command
            throttleTimer?.invalidate()
            throttleTimer = nil
            pendingCommand = nil
        } else {
            // Too soon, schedule for later
            pendingCommand = { [weak self] in
                self?.executeSendCommand()
                self?.lastCommandTime = Date()
            }

            // Only create timer if one doesn't exist
            if throttleTimer == nil {
                let delay = commandInterval - timeSinceLastCommand
                throttleTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.pendingCommand?()
                    self?.pendingCommand = nil
                    self?.throttleTimer = nil
                }
            }
        }
    }

    private func executeSendCommand() {
        webSocketClient.sendDualControl(left: leftThrottle, right: rightThrottle)
    }

    // MARK: - Convenience Methods

    func stop() {
        leftThrottle = 0.0
        rightThrottle = 0.0
        sendDualControlCommand()
    }

    func sendPing() {
        webSocketClient.sendPing()
    }

    // MARK: - Cleanup

    deinit {
        disconnect()
        throttleTimer?.invalidate()
        throttleTimer = nil
        pendingCommand = nil
    }
}
