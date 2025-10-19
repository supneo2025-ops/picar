//
//  MotorThrottleView.swift
//  PiCar
//
//  Vertical throttle control for individual motor
//

import SwiftUI

struct MotorThrottleView: View {
    let label: String
    @Binding var value: Double
    let onValueChanged: (Double) -> Void

    private let sliderRange: ClosedRange<Double> = 0...1

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
                    value: Binding(
                        get: { (value + 1) / 2 },
                        set: { newValue in
                            let mapped = max(-1, min(1, (newValue * 2) - 1))
                            value = mapped
                            onValueChanged(mapped)
                        }
                    ),
                    in: sliderRange
                )
                .rotationEffect(.degrees(-90))
                .padding(.horizontal, 18)
            }
            .frame(width: 90, height: 240)

            Text(String(format: "% .2f", value))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            Button(action: {
                value = 0
                onValueChanged(0)
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
        MotorThrottleView(label: "Left", value: .constant(0.3)) { _ in }
    }
    .frame(width: 140, height: 360)
}

