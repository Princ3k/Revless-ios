// TakeoffLoader.swift
// Revless
//
// A pure-SwiftUI "paper plane taking off along a curved path" loader.
// Replaces the standard ProgressView during flight searches.
// No Lottie dependency — uses animatableData + GeometryEffect.

import SwiftUI

struct TakeoffLoader: View {

    var message: String = "Searching eligible routes…"

    @State private var progress: Double = 0
    @State private var opacity: Double = 0

    // Subtle trail dots
    @State private var trailScale: [CGFloat] = [1, 0.7, 0.4]

    private let accent = Color(red: 0.55, green: 0.60, blue: 0.98)

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                // Curved runway arc
                ArcShape()
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.08), accent.opacity(0.22), accent.opacity(0.08)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 6])
                    )
                    .frame(width: 180, height: 80)

                // Trail dots behind the plane
                ForEach(0..<3) { i in
                    let frac = max(0, progress - Double(i + 1) * 0.10)
                    let pt = arcPoint(fraction: frac, width: 180, height: 80)
                    Circle()
                        .fill(accent.opacity(0.35 - Double(i) * 0.10))
                        .frame(width: 4 - CGFloat(i), height: 4 - CGFloat(i))
                        .offset(x: pt.x - 90, y: pt.y - 40)
                }

                // The plane
                let pt = arcPoint(fraction: progress, width: 180, height: 80)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [accent, Color(red: 0.38, green: 0.44, blue: 0.98)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: accent.opacity(0.5), radius: 8, y: 2)
                    .rotationEffect(.degrees(planeAngle(fraction: progress, width: 180, height: 80)))
                    .offset(x: pt.x - 90, y: pt.y - 40)
                    .animation(.easeInOut(duration: 2.2), value: progress)
            }
            .frame(width: 180, height: 80)

            VStack(spacing: 6) {
                Text(message)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Text("Checking your ZED agreements…")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.40))
            }
            .multilineTextAlignment(.center)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { opacity = 1 }
            animateLoop()
        }
    }

    private func animateLoop() {
        progress = 0
        withAnimation(.easeInOut(duration: 2.2)) { progress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            progress = 0
            animateLoop()
        }
    }

    /// Point along a parabolic arc from left-bottom to right-top.
    private func arcPoint(fraction f: Double, width: CGFloat, height: CGFloat) -> CGPoint {
        let x = CGFloat(f) * width
        let y = height - (4 * CGFloat(f) * (1 - CGFloat(f)) * height)
        return CGPoint(x: x, y: y)
    }

    private func planeAngle(fraction f: Double, width: CGFloat, height: CGFloat) -> Double {
        let delta = 0.01
        let p0 = arcPoint(fraction: max(0, f - delta), width: width, height: height)
        let p1 = arcPoint(fraction: min(1, f + delta), width: width, height: height)
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        return atan2(Double(dy), Double(dx)) * 180 / .pi - 45
    }
}

private struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.1)
        )
        return p
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.06, blue: 0.14).ignoresSafeArea()
        TakeoffLoader()
    }
}
