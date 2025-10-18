//
//  VideoStreamView.swift
//  PiCarController
//
//  MJPEG video stream display
//

import SwiftUI

struct VideoStreamView: View {
    let serverIP: String
    let serverPort: Int

    @State private var isLoading = true
    @State private var hasError = false
    @State private var refreshID = UUID()

    private var videoURL: URL? {
        URL(string: "http://\(serverIP):\(serverPort)/video")
    }

    var body: some View {
        ZStack {
            // Background
            Color.black

            // Video stream or placeholder
            if let url = videoURL {
                MJPEGStreamView(url: url, isLoading: $isLoading, hasError: $hasError)
                    .id(refreshID)
            } else {
                errorView
            }

            // Loading indicator
            if isLoading && !hasError {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Connecting to camera...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }

            // Error overlay
            if hasError {
                errorView
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
        .cornerRadius(10)
        .onAppear {
            refreshStream()
        }
    }

    private var errorView: some View {
        VStack(spacing: 15) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.6))

            Text("Camera Unavailable")
                .font(.headline)
                .foregroundColor(.white)

            Text("Tap to retry")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Button(action: refreshStream) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(8)
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
        .onTapGesture {
            refreshStream()
        }
    }

    private func refreshStream() {
        isLoading = true
        hasError = false
        refreshID = UUID()
    }
}

// MARK: - MJPEG Stream View

struct MJPEGStreamView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var hasError: Bool

    func makeUIView(context: Context) -> MJPEGImageView {
        let imageView = MJPEGImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.delegate = context.coordinator
        return imageView
    }

    func updateUIView(_ uiView: MJPEGImageView, context: Context) {
        if uiView.streamURL != url {
            uiView.load(url: url)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, hasError: $hasError)
    }

    class Coordinator: MJPEGImageViewDelegate {
        @Binding var isLoading: Bool
        @Binding var hasError: Bool

        init(isLoading: Binding<Bool>, hasError: Binding<Bool>) {
            _isLoading = isLoading
            _hasError = hasError
        }

        func mjpegImageView(_ imageView: MJPEGImageView, didReceiveFirstFrame: Bool) {
            DispatchQueue.main.async {
                self.isLoading = false
                self.hasError = !didReceiveFirstFrame
            }
        }

        func mjpegImageView(_ imageView: MJPEGImageView, didFailWithError error: Error) {
            DispatchQueue.main.async {
                self.isLoading = false
                self.hasError = true
            }
        }
    }
}

// MARK: - MJPEG Image View Delegate

protocol MJPEGImageViewDelegate: AnyObject {
    func mjpegImageView(_ imageView: MJPEGImageView, didReceiveFirstFrame: Bool)
    func mjpegImageView(_ imageView: MJPEGImageView, didFailWithError error: Error)
}

// MARK: - MJPEG Image View

class MJPEGImageView: UIImageView {
    weak var delegate: MJPEGImageViewDelegate?
    private(set) var streamURL: URL?

    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var receivedData = Data()
    private var isFirstFrame = true

    private let boundary = "--frame"

    func load(url: URL) {
        stop()

        streamURL = url
        isFirstFrame = true
        receivedData.removeAll()

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = session?.dataTask(with: url)
        task?.resume()
    }

    func stop() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }

    deinit {
        stop()
    }
}

// MARK: - URLSessionDataDelegate

extension MJPEGImageView: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
        processReceivedData()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("MJPEG stream error: \(error.localizedDescription)")
            delegate?.mjpegImageView(self, didFailWithError: error)
        }
    }

    private func processReceivedData() {
        // Look for JPEG boundaries in the data
        guard let boundaryData = boundary.data(using: .utf8) else { return }

        while let range = receivedData.range(of: boundaryData) {
            // Extract frame data before boundary
            let frameData = receivedData.subdata(in: 0..<range.lowerBound)

            // Remove processed data
            receivedData.removeSubrange(0..<range.upperBound)

            // Try to create image from frame data
            if let image = extractImageFromFrame(frameData) {
                DispatchQueue.main.async {
                    self.image = image

                    if self.isFirstFrame {
                        self.isFirstFrame = false
                        self.delegate?.mjpegImageView(self, didReceiveFirstFrame: true)
                    }
                }
            }
        }

        // Limit buffer size to prevent memory issues
        if receivedData.count > 1_000_000 {
            receivedData.removeAll()
        }
    }

    private func extractImageFromFrame(_ data: Data) -> UIImage? {
        // Look for JPEG start marker (FF D8) and end marker (FF D9)
        guard let jpegStartRange = data.range(of: Data([0xFF, 0xD8])),
              let jpegEndRange = data.range(of: Data([0xFF, 0xD9]), in: jpegStartRange.lowerBound..<data.endIndex) else {
            return nil
        }

        let jpegData = data.subdata(in: jpegStartRange.lowerBound..<jpegEndRange.upperBound)
        return UIImage(data: jpegData)
    }
}

// MARK: - Preview

struct VideoStreamView_Previews: PreviewProvider {
    static var previews: some View {
        VideoStreamView(
            serverIP: "192.168.100.148",
            serverPort: 5000
        )
        .frame(height: 300)
        .padding()
    }
}
