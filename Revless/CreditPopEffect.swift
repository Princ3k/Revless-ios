// CreditPopEffect.swift
// Revless
//
// Star-burst particle confetti that fires when search credits increase.
// Add as an overlay on the credits number view.
// Usage: .overlay { CreditPopEffect(trigger: creditValue) }

import SwiftUI

// MARK: - Particle model

private struct StarParticle: Identifiable {
    let id   = UUID()
    var x:     CGFloat
    var y:     CGFloat
    var scale: CGFloat
    var angle: Double     // radians, random
    var speed: CGFloat
    var color: Color
    var opacity: Double = 1
}

// MARK: - Main view

struct CreditPopEffect: View {

    /// Pass the current credit value. The effect fires whenever this increases.
    var trigger: Int

    @State private var particles: [StarParticle] = []
    @State private var prevTrigger: Int = 0

    private let colors: [Color] = [
        Color(red: 1.0, green: 0.85, blue: 0.25),
        Color(red: 0.55, green: 0.60, blue: 0.98),
        Color(red: 1.0, green: 0.55, blue: 0.12),
        Color(red: 0.80, green: 0.30, blue: 0.90),
        Color(red: 0.30, green: 0.85, blue: 0.55),
    ]

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Image(systemName: "star.fill")
                    .font(.system(size: 9 * p.scale))
                    .foregroundStyle(p.color)
                    .opacity(p.opacity)
                    .position(x: p.x, y: p.y)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { old, new in
            if new > old { fire() }
            prevTrigger = new
        }
        .onAppear { prevTrigger = trigger }
    }

    private func fire() {
        let count = 18
        var burst: [StarParticle] = (0..<count).map { _ in
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = CGFloat.random(in: 40...110)
            return StarParticle(
                x: 0, y: 0,
                scale: CGFloat.random(in: 0.6...1.4),
                angle: angle,
                speed: speed,
                color: colors.randomElement()!
            )
        }
        particles = burst

        withAnimation(.easeOut(duration: 0.9)) {
            for i in burst.indices {
                let dx = CGFloat(cos(burst[i].angle)) * burst[i].speed
                let dy = CGFloat(sin(burst[i].angle)) * burst[i].speed
                burst[i].x += dx
                burst[i].y += dy
                burst[i].opacity = 0
            }
            particles = burst
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles = []
        }
    }
}
