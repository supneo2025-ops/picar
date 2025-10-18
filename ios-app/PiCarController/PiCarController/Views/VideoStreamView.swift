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
        .frame(maxWidth: .infinity)
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

    private let jpegStartMarker = Data([0xFF, 0xD8])
    private let jpegEndMarker = Data([0xFF, 0xD9])

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
        if let startRange = receivedData.range(of: jpegStartMarker), startRange.lowerBound > 0 {
            receivedData.removeSubrange(0..<startRange.lowerBound)
        } else if !receivedData.isEmpty && !receivedData.starts(with: jpegStartMarker) {
            if receivedData.count > 1_000_000 {
                receivedData.removeAll(keepingCapacity: true)
            }
            return
        }

        while let startRange = receivedData.range(of: jpegStartMarker),
              let endRange = receivedData.range(of: jpegEndMarker, in: startRange.lowerBound..<receivedData.endIndex) {

            let frameData = receivedData.subdata(in: startRange.lowerBound..<endRange.upperBound)
            receivedData.removeSubrange(0..<endRange.upperBound)

            if let image = UIImage(data: frameData) {
                DispatchQueue.main.async {
                    self.image = image

                    if self.isFirstFrame {
                        self.isFirstFrame = false
                        self.delegate?.mjpegImageView(self, didReceiveFirstFrame: true)
                    }
                }
            }
        }

        if let startRange = receivedData.range(of: jpegStartMarker), startRange.lowerBound > 0 {
            receivedData.removeSubrange(0..<startRange.lowerBound)
        } else if receivedData.count > 1_000_000 {
            receivedData.removeAll(keepingCapacity: true)
        }
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
