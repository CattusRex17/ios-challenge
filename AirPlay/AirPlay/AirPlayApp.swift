//
//  ContentView.swift
//  AirPlay
//
//  Created by Mauricio Rodriguez on 6/8/2025.
//

import SwiftUI
import PhotosUI
import AVKit
import MediaPlayer

// MARK: - Logger
class PlaybackLogger {
    static let shared = PlaybackLogger()
    private init() {}

    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[PlaybackLog] \(timestamp): \(message)")
    }
}


// MARK: - ContentView
struct ContentView: View {
    @State private var selectedVideoURL: URL?
    @State private var isAirPlayActive: Bool = false
    @State private var showPicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let url = selectedVideoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 300)
                        .onAppear {
                            PlaybackLogger.shared.log("Video cargado en el reproductor: \(url.lastPathComponent)")
                            checkAirPlayStatus()
                        }
                } else {
                    Text("Selecciona un video para comenzar")
                        .foregroundColor(.gray)
                        .padding()
                }

                Button("Seleccionar video") {
                    showPicker = true
                    PlaybackLogger.shared.log("Usuario inició selección de video")
                }

                AirPlayButtonView()
                    .frame(width: 44, height: 44)
                    .padding()

                if UIScreen.screens.count > 1 {
                    Text("AirPlay activo: contenido se transmite")
                        .foregroundColor(.green)
                        .onAppear {
                            PlaybackLogger.shared.log("AirPlay detectado: hay una segunda pantalla activa")
                        }
                } else {
                    Text("AirPlay no está activo")
                        .foregroundColor(.red)
                        .onAppear {
                            PlaybackLogger.shared.log("AirPlay no está activo")
                        }
                }
            }
            .padding()
            .navigationTitle("AirPlay Demo")
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker { url in
                self.selectedVideoURL = url
                PlaybackLogger.shared.log("Video seleccionado: \(url.lastPathComponent)")
            }
        }
    }

    private func checkAirPlayStatus() {
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            if output.portType == .airPlay {
                PlaybackLogger.shared.log("Salida de audio actual: AirPlay - \(output.portName)")
            }
        }
    }
}


// MARK: - Video Picker
struct VideoPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.hasItemConformingToTypeIdentifier("public.movie") else { return }

            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, _ in
                guard let url = url else { return }
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: tempURL)
                DispatchQueue.main.async {
                    self.onPick(tempURL)
                }
            }
        }
    }
}


// MARK: - AirPlay Button (AVRoutePickerView)
struct AirPlayButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.activeTintColor = .systemBlue
        view.tintColor = .gray
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}


// MARK: - App Entry Point
@main
struct AirPlayPOCApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
