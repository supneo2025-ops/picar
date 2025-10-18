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
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()

                    // Joystick control
                    joystickSection
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

    // MARK: - Joystick Section

    private var joystickSection: some View {
        VStack(spacing: 15) {
            // Position display
            positionDisplay

            // Joystick
            JoystickView(size: 250) { position in
                viewModel.updateJoystickPosition(position)
            }

            // Control hints
            controlHints
        }
        .padding(.horizontal, 20)
    }

    private var positionDisplay: some View {
        HStack(spacing: 30) {
            // X position
            VStack(spacing: 4) {
                Text("Turn")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 4) {
                    Image(systemName: viewModel.currentPosition.x < -0.1 ? "arrow.left.circle.fill" :
                          viewModel.currentPosition.x > 0.1 ? "arrow.right.circle.fill" : "circle")
                        .foregroundColor(.blue)

                    Text(String(format: "%.2f", viewModel.currentPosition.x))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 50)
                }
            }

            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 30)

            // Y position
            VStack(spacing: 4) {
                Text("Speed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 4) {
                    Image(systemName: viewModel.currentPosition.y > 0.1 ? "arrow.up.circle.fill" :
                          viewModel.currentPosition.y < -0.1 ? "arrow.down.circle.fill" : "circle")
                        .foregroundColor(.blue)

                    Text(String(format: "%.2f", viewModel.currentPosition.y))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 50)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    private var controlHints: some View {
        VStack(spacing: 6) {
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12))
                    Text("Forward")
                        .font(.caption)
                }

                HStack(spacing: 6) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12))
                    Text("Backward")
                        .font(.caption)
                }
            }

            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12))
                    Text("Turn Left")
                        .font(.caption)
                }

                HStack(spacing: 6) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                    Text("Turn Right")
                        .font(.caption)
                }
            }
        }
        .foregroundColor(.white.opacity(0.6))
    }
}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(CarControlViewModel())
    }
}
