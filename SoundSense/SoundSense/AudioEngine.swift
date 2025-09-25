//
//  ContentView.swift
//  SoundSense
//
//  Created by Daniela Valadares on 25/09/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioEngine: ObservableObject {
    static let shared = AudioEngine()

    @Published private(set) var rmsLevel: Float = 0.0 // 0.0 .. 1.0

    private let engine = AVAudioEngine()
    private var inputFormat: AVAudioFormat?
    private var isRunning = false

    private init() {
        configureSession()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
            try session.setActive(true, options: [])
        } catch {
            print("AudioSession erro: \(error.localizedDescription)")
        }
    }

    func start() {
        guard !isRunning else { return }
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputFormat = format

        // Remove taps se houver
        inputNode.removeTap(onBus: 0)

        // Instala tap para receber buffers
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.process(buffer: buffer)
        }

        do {
            engine.prepare()
            try engine.start()
            isRunning = true
            print("AudioEngine: started")
        } catch {
            print("AudioEngine start erro: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        print("AudioEngine: stopped")
    }

    private func process(buffer: AVAudioPCMBuffer) {
        // Calcula RMS do primeiro canal (assumimos Float32 formato)
        guard let channelData = buffer.floatChannelData else { return }
        let channel = channelData[0]
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0.0

        // soma quadrados das amostras
        for i in 0..<frameLength {
            let sample = channel[i]
            sum += sample * sample
        }
        let meanSquare = sum / Float(frameLength)
        let rms = sqrt(meanSquare)

        // Normaliza (valor típico do RMS em voz = ~0.01..0.2; ajustamos para UI)
        // Clamp para [0,1]
        let normalized = min(max((rms * 10.0), 0.0), 1.0)

        // Atualiza publisher na main
        Task { @MainActor in
            self.rmsLevel = normalized
        }
    }
}
