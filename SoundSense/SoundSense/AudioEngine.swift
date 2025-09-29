//
//  ContentView.swift
//  SoundSense
//
//  Created by Daniela Valadares on 25/09/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor // Todas as propriedades e métodos desta classe serão executados na thread principal
final class AudioEngine: ObservableObject { // É necessáro uma vez que a UI permitindo que reaja automaticamente
    static let shared = AudioEngine() // Singleton padrão

    @Published private(set) var rmsLevel: Float = 0.0 // 0.0 .. 1.0
    // @Published permite que as Views observem o valor
    // private(set) permite que o valor seja lido externamente, mas só poderá ser modificado dentro desta classe

    private let engine = AVAudioEngine() // Conecta e gerencia os nós de áudio, como o microfone
    private var inputFormat: AVAudioFormat?
    private var isRunning = false

    private init() {
        configureSession() // configura o microfone imediatamente
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance() // Pega a instância compartilhada da sessão de áudio
        do {
            try session.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
            // .record define a finalidade como gravação (entrada de áudio)
            // mode: .measurement modo otimizado para análise de áudio de baixa latência e alta qualidade
            // .allowBluetooth permite o uso de dispositivos de áudio Bluetooth como entrada
            try session.setActive(true, options: []) // Ativa a sessão de áudio
        } catch {
            print("AudioSession erro: \(error.localizedDescription)")
        }
    }

    func start() {
        guard !isRunning else { return } // Impede que o código seja executado se o motor já estiver ligado
        let inputNode = engine.inputNode // Nó que representa o microfone
        let format = inputNode.outputFormat(forBus: 0)
        inputFormat = format

        // Remove taps se houver, garantindo que qualquer escuta anterior (tap) seja removida
        inputNode.removeTap(onBus: 0)

        // Instala tap para receber buffers
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.process(buffer: buffer) // A cada buffer recebido, a função é chamada para calcular o RMS
        }

        // Inicia e prepara o motor para receber o fluxo de dados
        do {
            engine.prepare()
            try engine.start()
            isRunning = true
            print("AudioEngine: started")
        } catch {
            print("AudioEngine start erro: \(error.localizedDescription)")
        }
    }

    // Remove o tap, interrompendo a chamada repetida da função
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
