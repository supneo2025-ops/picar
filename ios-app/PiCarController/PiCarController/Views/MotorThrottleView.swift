//
//  MotorThrottleView.swift
//  PiCarController
//
//  Vertical throttle control for individual motor
//

import SwiftUI

struct MotorThrottleView: View {
    let label: String
    @Binding var value: Double
    let onValueChanged: (Double) -> Void

    private let sliderRange: ClosedRange<Double> = 0...1
    @State private var localValue: Double = 0.5
    @State private var isInitialized: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.08))

                VStack {
                    Text("FWD")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.8))
                    Spacer()
                    Text("REV")
                        .font(.caption2)
                        .foregroundColor(.red.opacity(0.8))
                }
                .padding(.vertical, 8)

                Slider(
                    value: $localValue,
                    in: sliderRange,
                    onEditingChanged: { editing in
                        if !editing && isInitialized {
                            // User finished dragging - send final value
                            let mapped = (localValue * 2) - 1
                            onValueChanged(mapped)
                        }
                    }
                )
                .onChange(of: localValue) { newValue in
                    // Only send updates after initialization
                    guard isInitialized else { return }
                    let mapped = (newValue * 2) - 1
                    onValueChanged(mapped)
                }
                .rotationEffect(.degrees(-90))
                .padding(.horizontal, 18)
            }
            .frame(width: 90, height: 240)
            .onAppear {
                // Initialize local value from binding
                localValue = (value + 1) / 2
                // Mark as initialized to start sending updates
                isInitialized = true
            }
            .onChange(of: value) { newValue in
                // Update local value when external value changes (but don't send back)
                let normalized = (newValue + 1) / 2
                if abs(normalized - localValue) > 0.01 {
                    localValue = normalized
                }
            }

            Text(String(format: "% .2f", value))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Button(action: {
                localValue = 0.5  // Center position (maps to 0)
                if isInitialized {
                    onValueChanged(0)
                }
            }) {
                Text("Center")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        MotorThrottleView(label: "Left", value: .constant(-0.4)) { _ in }
    }
    .frame(width: 140, height: 360)
}

