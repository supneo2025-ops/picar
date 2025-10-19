//
//  MainView.swift
//  PiCarController
//
//  Main control interface
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: CarControlViewModel

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 20
            let videoWidth = max(geometry.size.width - (horizontalPadding * 2), 0)

            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.15, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, geometry.safeAreaInsets.top)

                    // Video stream
                    VideoStreamView(
                        serverIP: WebSocketClient.PI_SERVER_IP,
                        serverPort: WebSocketClient.PI_SERVER_PORT
                    )
                    .frame(width: videoWidth)
                    .frame(height: videoWidth * 3 / 4)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 20)

                    Spacer()

                    // Motor controls
                    motorControlSection
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                }
            }
        }
        .onAppear {
            viewModel.connect()
        }
        .onDisappear {
            viewModel.stop()
            viewModel.disconnect()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // Title
                HStack(spacing: 10) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Pi Car Controller")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Connection status
                connectionStatusView
            }
            .padding(.horizontal, 20)

            // Error message
            if let error = viewModel.lastError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
        }
    }

    private var connectionStatusView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
                .shadow(color: viewModel.isConnected ? .green : .red, radius: 4)

            Text(viewModel.isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }

    // MARK: - Motor Controls

    private var motorControlSection: some View {
        VStack(spacing: 18) {
            motorStatus

            HStack(spacing: 24) {
                MotorThrottleView(
                    label: "Left Motor",
                    value: $viewModel.leftThrottle
                ) { value in
                    viewModel.updateLeftThrottle(value)
                }

                MotorThrottleView(
                    label: "Right Motor",
                    value: $viewModel.rightThrottle
                ) { value in
                    viewModel.updateRightThrottle(value)
                }
            }

            controlHints
        }
        .padding(.horizontal, 20)
    }

    private var motorStatus: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Left Output")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(String(format: "% .2f", viewModel.leftThrottle))
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text("Right Output")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(String(format: "% .2f", viewModel.rightThrottle))
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    private var controlHints: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12))
                Text("Push up for forward drive")
                    .font(.caption)
            }

            HStack(spacing: 12) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 12))
                Text("Push down for reverse")
                    .font(.caption)
            }

            Text("Use each slider to independently control the left/right motor speed and direction.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))
        }
        .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(CarControlViewModel())
    }
}
