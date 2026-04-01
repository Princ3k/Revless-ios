// DocumentReviewView.swift
// Revless
//
// Peer-review detail: authenticated file preview + primary verify CTA.

import PDFKit
import SwiftUI
import UIKit

struct DocumentReviewView: View {

    let document: PendingDocumentSummary
    var onFinished: () -> Void
    var onMatrixNeedsRefresh: () async -> Void

    @Environment(AuthViewModel.self) private var auth

    @State private var fileData: Data?
    @State private var loadError: String?
    @State private var isLoadingFile = true
    @State private var isVerifying = false
    @State private var verifyError: String?
    @State private var showOfficialBanner = false

    private let bg = LinearGradient(
        colors: [Color(hex: "#0A0E17"), Color(hex: "#1A1A2E")],
        startPoint: .top,
        endPoint: .bottom
    )
    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)
    private let subtleText = Color.white.opacity(0.45)
    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.38, green: 0.44, blue: 0.98),
            Color(red: 0.55, green: 0.28, blue: 0.92),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard

                        previewSection
                            .frame(minHeight: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        if showOfficialBanner {
                            officialNote
                        }

                        verifyButton
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Review document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { onFinished() }
                }
            }
            .preferredColorScheme(.dark)
            .task { await loadFile() }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(document.carrierIata) · \(document.carrierName)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Uploaded by \(document.uploaderEmail)")
                .font(.system(size: 13))
                .foregroundStyle(subtleText)

            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(accentColor)
                Text("\(document.approvalCount)/\(document.requiredApprovals) peer approvals")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background { glass() }
    }

    @ViewBuilder
    private var previewSection: some View {
        if isLoadingFile {
            ProgressView()
                .tint(accentColor)
                .frame(maxWidth: .infinity, minHeight: 280)
                .background(Color.white.opacity(0.06))
        } else if let err = loadError {
            Text(err)
                .font(.system(size: 14))
                .foregroundStyle(.orange.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color.white.opacity(0.06))
        } else if let data = fileData {
            if let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.35))
            } else {
                PDFKitRepresentedView(data: data)
                    .frame(minHeight: 360)
                    .background(Color.black.opacity(0.45))
            }
        }
    }

    private var officialNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text("This agreement is now official for your airline. Rules were updated.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.green.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.25), lineWidth: 0.5)
                )
        )
    }

    private var verifyButton: some View {
        VStack(spacing: 10) {
            if let err = verifyError {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundStyle(.orange.opacity(0.95))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await runApprove() }
            } label: {
                Text("Verify agreement")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(ctaGradient)
                            .shadow(color: accentColor.opacity(0.55), radius: 22, y: 10)
                    }
            }
            .buttonStyle(.plain)
            .disabled(isVerifying || isLoadingFile || fileData == nil || document.status != "pending")
            .opacity((isVerifying || fileData == nil) ? 0.55 : 1)
        }
    }

    private func glass() -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
            }
    }

    @MainActor
    private func loadFile() async {
        isLoadingFile = true
        loadError = nil
        defer { isLoadingFile = false }
        do {
            fileData = try await NetworkManager.shared.downloadAgreementDocumentFile(documentId: document.id)
        } catch {
            loadError = "Could not load the file. Check your connection and try again."
        }
    }

    @MainActor
    private func runApprove() async {
        verifyError = nil
        isVerifying = true
        defer { isVerifying = false }
        do {
            let res = try await NetworkManager.shared.approveAgreementDocument(documentId: document.id)
            await auth.refreshCurrentUser()
            if res.documentNowOfficial {
                showOfficialBanner = true
            }
            await onMatrixNeedsRefresh()
            if res.documentNowOfficial {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                onFinished()
            }
        } catch NetworkError.conflict {
            verifyError = "You’ve already approved this document."
        } catch let e as NetworkError {
            verifyError = e.errorDescription
        } catch {
            verifyError = error.localizedDescription
        }
    }
}

// MARK: - PDFKit

private struct PDFKitRepresentedView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.document = PDFDocument(data: data)
        return v
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(data: data)
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r, g, b: UInt64
        switch hex.count {
        case 3:  (r, g, b) = ((value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:  (r, g, b) = (value >> 16, value >> 8 & 0xFF, value & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
