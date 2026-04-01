// HapticEngine.swift
// Revless
//
// Thin UIKit haptic wrapper so SwiftUI views stay declarative.
// All functions are safe to call from any thread.

import UIKit

enum HapticEngine {

    /// Light tap — search success, credit earned, verification submitted.
    static func success() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }

    /// Medium tap — item selected, major action confirmed.
    static func select() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }

    /// Double heavy thud — 402 out-of-credits error.
    static func creditsDepleted() {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        g.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            g.impactOccurred()
        }
    }

    /// Notification success (system pattern) — document approved, milestone unlocked.
    static func notifySuccess() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    /// Notification warning — stale agreement detected.
    static func notifyWarning() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }
}
