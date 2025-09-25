//
//  LevelMeterView.swift
//  SoundSense
//
//  Created by Daniela Valadares on 25/09/25.
//

import SwiftUI

struct LevelMeterView: View {
    let level: Float // 0..1

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let filled = CGFloat(level) * width

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(height: height)
                    .opacity(0.15)
                    .foregroundStyle(.secondary)
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: filled, height: height)
                    .foregroundStyle(.linearGradient(stops: [
                        .init(color: .green, location: 0),
                        .init(color: .yellow, location: 0.7),
                        .init(color: .red, location: 1.0)
                    ], startPoint: .leading, endPoint: .trailing))
                    .animation(.linear(duration: 0.05), value: level)
            }
        }
    }
}
