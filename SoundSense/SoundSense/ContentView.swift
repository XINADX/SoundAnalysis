//
//  AudioEngine.swift
//  SoundSense
//
//  Created by Daniela Valadares on 25/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audio = AudioEngine.shared
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 24) {
            Text("SoundSense — Captura de Áudio")
                .font(.title2).bold()

            LevelMeterView(level: audio.rmsLevel)
                .frame(height: 160)
                .padding(.horizontal, 24)

            Text(String(format: "Nível: %.2f", audio.rmsLevel))
                .font(.headline)

            Button(action: toggle) {
                Text(isRunning ? "Parar captura" : "Iniciar captura")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke())
            }
            .padding(.horizontal, 24)
        }
        .padding()
    }

    private func toggle() {
        if isRunning {
            audio.stop()
        } else {
            audio.start()
        }
        isRunning.toggle()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
