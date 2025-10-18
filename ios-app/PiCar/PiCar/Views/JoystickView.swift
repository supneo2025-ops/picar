//
//  JoystickView.swift
//  PiCarController
//
//  Custom joystick control for car movement
//

import SwiftUI

struct JoystickView: View {
    // MARK: - Configuration

    let size: CGFloat
    let onPositionChanged: (CGPoint) -> Void

    // MARK: - State

    @State private var thumbPosition: CGPoint = .zero
    @GestureState private var isDragging = false

    // MARK: - Constants

    private let thumbSize: CGFloat
    private let deadZone: CGFloat = 0.15

    init(size: CGFloat = 200, onPositionChanged: @escaping (CGPoint) -> Void) {
        self.size = size
        self.thumbSize = size * 0.35
        self.onPositionChanged = onPositionChanged
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.2)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                )

            // Directional indicators
            directionalMarkers

            // Center dot
            Circle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 8, height: 8)

            // Thumb/handle
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.blue
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: thumbSize / 2
                    )
                )
                .frame(width: thumbSize, height: thumbSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                .offset(x: thumbPosition.x, y: thumbPosition.y)
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                .gesture(
                    DragGesture()
                        .updating($isDragging) { _, state, _ in
                            state = true
                        }
                        .onChanged { value in
                            handleDrag(value.translation)
                        }
                        .onEnded { _ in
                            returnToCenter()
                        }
                )
        }
        .frame(width: size, height: size)
    }

    // MARK: - Directional Markers

    private var directionalMarkers: some View {
        ZStack {
            // Forward arrow
            Image(systemName: "arrow.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
                .offset(y: -size / 2 + 30)

            // Backward arrow
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
                .offset(y: size / 2 - 30)

            // Left arrow
            Image(systemName: "arrow.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
                .offset(x: -size / 2 + 30)

            // Right arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
                .offset(x: size / 2 - 30)
        }
    }

    // MARK: - Gesture Handling

    private func handleDrag(_ translation: CGSize) {
        // Calculate new position
        let maxRadius = (size - thumbSize) / 2
        let newX = translation.width
        let newY = translation.height

        // Calculate distance from center
        let distance = sqrt(newX * newX + newY * newY)

        // Constrain to circle boundary
        if distance > maxRadius {
            let angle = atan2(newY, newX)
            thumbPosition = CGPoint(
                x: maxRadius * cos(angle),
                y: maxRadius * sin(angle)
            )
        } else {
            thumbPosition = CGPoint(x: newX, y: newY)
        }

        // Convert to normalized coordinates (-1 to 1)
        let normalizedX = thumbPosition.x / maxRadius
        let normalizedY = -thumbPosition.y / maxRadius // Invert Y for intuitive control

        // Apply dead zone
        let adjustedX = abs(normalizedX) < deadZone ? 0 : normalizedX
        let adjustedY = abs(normalizedY) < deadZone ? 0 : normalizedY

        // Notify callback
        onPositionChanged(CGPoint(x: adjustedX, y: adjustedY))
    }

    private func returnToCenter() {
        // Animate return to center
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            thumbPosition = .zero
        }

        // Notify stop
        onPositionChanged(.zero)
    }
}

// MARK: - Preview

struct JoystickView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            JoystickView(size: 250) { position in
                print("Joystick: x=\(position.x), y=\(position.y)")
            }

            Text("Drag the joystick to control")
                .foregroundColor(.gray)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
