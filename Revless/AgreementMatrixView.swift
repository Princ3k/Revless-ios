// AgreementMatrixView.swift
// Revless
//
// Community agreement matrix + peer-review uploads (Aero-Glass).

import SwiftUI
import UniformTypeIdentifiers

struct AgreementMatrixView: View {

    @Environment(AuthViewModel.self) private var auth
    @State private var viewModel = AgreementMatrixViewModel()

    @State private var searchText = ""
    @State private var showImporter = false
    @State private var showCarrierSheet = false
    @State private var pendingUpload: (fileData: Data, fileName: String, mime: String)?
    @State private var carrierField = ""
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var reviewDoc: PendingDocumentSummary?

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

                if viewModel.isLoading && viewModel.matrix == nil {
                    ProgressView()
                        .tint(accentColor)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            pendingSection
                            currentAgreementsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationTitle("Agreements")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0A0E17"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search carrier or email")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(ctaGradient)
                    }
                    .accessibilityLabel("Upload agreement")
                }
            }
            .preferredColorScheme(.dark)
            .task { await viewModel.fetchMatrix() }
            .refreshable { await viewModel.fetchMatrix() }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showCarrierSheet) {
                carrierSheet
            }
            .sheet(item: $reviewDoc) { doc in
                DocumentReviewView(
                    document: doc,
                    onFinished: { reviewDoc = nil },
                    onMatrixNeedsRefresh: { await viewModel.fetchMatrix() }
                )
                .environment(auth)
            }
        }
    }

    // MARK: - Pending (horizontal)

    @ViewBuilder
    private var pendingSection: some View {
        let items = filteredPending
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Pending verification")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { doc in
                            pendingCard(doc)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func pendingCard(_ doc: PendingDocumentSummary) -> some View {
        Button {
            reviewDoc = doc
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(doc.carrierIata)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(doc.approvalCount)/\(doc.requiredApprovals)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                Text(doc.carrierName)
                    .font(.system(size: 12))
                    .foregroundStyle(subtleText)
                    .lineLimit(2)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(ctaGradient)
                            .frame(
                                width: geo.size.width * CGFloat(doc.approvalCount)
                                    / CGFloat(max(doc.requiredApprovals, 1))
                            )
                    }
                }
                .frame(height: 6)

                Text("Tap to review")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(subtleText.opacity(0.85))
            }
            .padding(16)
            .frame(width: 220, alignment: .leading)
            .background { glass(18) }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Current matrix

    private var currentAgreementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Current agreements")

            if let err = viewModel.errorMessage, viewModel.matrix == nil {
                Text(err)
                    .font(.system(size: 14))
                    .foregroundStyle(.orange.opacity(0.9))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { glass(18) }
            }

            let groups = groupedRules
            if groups.isEmpty && viewModel.matrix != nil && viewModel.errorMessage == nil {
                Text("No published rules yet. Upload an agreement for peer review.")
                    .font(.system(size: 14))
                    .foregroundStyle(subtleText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { glass(18) }
            }

            ForEach(groups, id: \.0) { iata, rows in
                carrierBlock(iata: iata, rows: rows)
            }
        }
    }

    private func carrierBlock(iata: String, rows: [MatrixRuleRow]) -> some View {
        let name = rows.first?.carrierName ?? ""
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(iata)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("·")
                    .foregroundStyle(subtleText)
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(subtleText)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ForEach(rows) { row in
                ruleRow(row)
                if row.ruleId != rows.last?.ruleId {
                    Divider().background(Color.white.opacity(0.07))
                        .padding(.leading, 16)
                }
            }
        }
        .background { glass(18) }
    }

    private func ruleRow(_ row: MatrixRuleRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.travelerType.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(row.isUnaccompaniedAllowed ? "Unaccompanied allowed" : "Must be accompanied")
                    .font(.system(size: 11))
                    .foregroundStyle(subtleText)
            }
            Spacer()
            zedBadge(row.zedTier)
            statusMini(row)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func zedBadge(_ tier: ZedTier) -> some View {
        let (fg, bg): (Color, Color) = {
            switch tier {
            case .low:    return (.orange, Color.orange.opacity(0.15))
            case .medium: return (accentColor, accentColor.opacity(0.15))
            case .high:   return (.green, Color.green.opacity(0.15))
            }
        }()
        return Text("ZED \(tier.displayName)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func statusMini(_ row: MatrixRuleRow) -> some View {
        HStack(spacing: 4) {
            Image(systemName: row.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield")
                .font(.system(size: 12))
                .foregroundStyle(row.isVerified ? Color.green : Color.orange.opacity(0.85))
            if row.isStale {
                Text("Stale")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.orange.opacity(0.8))
            }
        }
        .frame(minWidth: 56, alignment: .trailing)
    }

    // MARK: - Upload sheet

    private var carrierSheet: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Upload for peer review")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Enter the partner airline IATA code this document covers (e.g. TK).")
                    .font(.system(size: 14))
                    .foregroundStyle(subtleText)
                    .multilineTextAlignment(.center)

                TextField("Carrier IATA", text: $carrierField)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background { glass(14) }

                if let err = uploadError {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await runUpload() }
                } label: {
                    Text(isUploading ? "Uploading…" : "Submit")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(ctaGradient)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isUploading || carrierField.filter(\.isLetter).count != 3)

                Button("Cancel") {
                    showCarrierSheet = false
                    pendingUpload = nil
                }
                .foregroundStyle(subtleText)
            }
            .padding(24)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Derived

    private var filteredPending: [PendingDocumentSummary] {
        guard let p = viewModel.matrix?.pendingDocuments else { return [] }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return p }
        return p.filter {
            $0.carrierIata.lowercased().contains(q)
                || $0.carrierName.lowercased().contains(q)
                || $0.uploaderEmail.lowercased().contains(q)
        }
    }

    private var groupedRules: [(String, [MatrixRuleRow])] {
        guard let rules = viewModel.matrix?.rules else { return [] }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered: [MatrixRuleRow]
        if q.isEmpty {
            filtered = rules
        } else {
            filtered = rules.filter {
                $0.carrierIata.lowercased().contains(q) || $0.carrierName.lowercased().contains(q)
            }
        }
        let dict = Dictionary(grouping: filtered, by: \.carrierIata)
        return dict.keys.sorted().map { key in
            (key, dict[key]!.sorted {
                $0.travelerType.rawValue < $1.travelerType.rawValue
                    || ($0.travelerType == $1.travelerType && $0.zedTier.rawValue < $1.zedTier.rawValue)
            })
        }
    }

    // MARK: - Actions

    private func handleImport(_ result: Result<[URL], Error>) {
        uploadError = nil
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let name = url.lastPathComponent
                pendingUpload = (fileData: data, fileName: name, mime: mimeForFileName(name))
                carrierField = ""
                showCarrierSheet = true
            } catch {
                uploadError = "Could not read the file."
            }
        case .failure(let e):
            uploadError = e.localizedDescription
        }
    }

    @MainActor
    private func runUpload() async {
        guard let pu = pendingUpload else { return }
        let iata = String(carrierField.uppercased().filter(\.isLetter).prefix(3))
        guard iata.count == 3 else {
            uploadError = "Enter a 3-letter IATA code."
            return
        }
        isUploading = true
        uploadError = nil
        defer { isUploading = false }
        do {
            try await viewModel.uploadDocument(
                data: pu.fileData,
                fileName: pu.fileName,
                mimeType: pu.mime,
                carrierIata: iata
            )
            showCarrierSheet = false
            pendingUpload = nil
            await auth.refreshCurrentUser()
        } catch {
            uploadError = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func mimeForFileName(_ name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "webp": return "image/webp"
        default: return "application/octet-stream"
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(subtleText)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private func glass(_ cornerRadius: CGFloat = 20) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
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

#Preview {
    AgreementMatrixView()
        .environment(AuthViewModel())
}
