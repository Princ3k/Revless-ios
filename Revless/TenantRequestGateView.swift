// TenantRequestGateView.swift
// Revless
//
// Shown when the user is signed in but has no tenant (unsupported work email domain).
// They can request their airline be added; admins approve via the Admin API.

import SwiftUI

struct TenantRequestGateView: View {

    @Environment(AuthViewModel.self) private var auth

    @State private var latestRequest: TenantRequestRead?
    @State private var isLoading = true
    @State private var actionError: String?
    @State private var isSubmitting = false

    @State private var airlineName = ""
    @State private var airlineCode = ""
    @State private var notes = ""

    private let bg = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.06, blue: 0.14),
            Color(red: 0.07, green: 0.07, blue: 0.11),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let accentBlue = Color(red: 0.38, green: 0.44, blue: 0.98)
    private let subtleText = Color.white.opacity(0.45)
    private let fieldBackground = Color.white.opacity(0.07)
    private let fieldBorder = Color.white.opacity(0.12)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if isLoading {
                        ProgressView()
                            .tint(accentBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        statusOrForm
                    }

                    if let err = actionError {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.9))
                            .padding(.top, 4)
                    }

                    legalFooter
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .refreshable { await reload() }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Sign out") { auth.logout() }
                    .foregroundStyle(accentBlue)
            }
        }
        .task { await reload() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Airline workspace")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(
                "Your email domain is not set up on Revless yet. "
                    + "Request your airline below — when approved, you and colleagues on the same work domain can use searches and the agreement matrix."
            )
            .font(.subheadline)
            .foregroundStyle(subtleText)
            .fixedSize(horizontal: false, vertical: true)

            if let email = auth.currentUser?.email {
                Text(email)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var statusOrForm: some View {
        if let req = latestRequest {
            switch req.status {
            case .pending:
                statusCard(
                    title: "Request received",
                    detail: "We’re reviewing \(req.airlineName) (\(req.airlineCode)) for @\(req.emailDomain). You’ll get access once your workspace is enabled — pull down to refresh.",
                    systemImage: "clock.fill",
                    tint: .orange
                )
            case .approved:
                statusCard(
                    title: "Approved",
                    detail: "Your airline workspace should be active. Pull to refresh your profile, or sign out and sign in again.",
                    systemImage: "checkmark.circle.fill",
                    tint: Color(red: 0.3, green: 0.85, blue: 0.55)
                )
                Button {
                    Task { await auth.refreshCurrentUser() }
                } label: {
                    Text("Refresh profile")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(accentBlue.opacity(0.35))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            case .rejected:
                statusCard(
                    title: "Request not approved",
                    detail: req.adminNote ?? "You can submit a new request with updated details.",
                    systemImage: "xmark.circle.fill",
                    tint: .red.opacity(0.85)
                )
                requestForm
            }
        } else {
            requestForm
        }
    }

    private func statusCard(title: String, detail: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var requestForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Request your airline")
                .font(.headline)
                .foregroundStyle(.white)

            labeledField("Airline name", placeholder: "e.g. Delta Air Lines", text: $airlineName)
            labeledField("IATA code", placeholder: "e.g. DL", text: $airlineCode)
                .textInputAutocapitalization(.characters)

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (optional)")
                    .font(.caption)
                    .foregroundStyle(subtleText)
                TextField("Anything that helps verify your airline", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(fieldBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(fieldBorder, lineWidth: 1)
                            }
                    }
            }

            Button {
                Task { await submitRequest() }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accentBlue, Color(red: 0.55, green: 0.28, blue: 0.92)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Submit request")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 52)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting || !formIsValid)
            .opacity(formIsValid ? 1 : 0.45)
        }
    }

    private var formIsValid: Bool {
        airlineName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
            && (2...3).contains(airlineCode.trimmingCharacters(in: .whitespacesAndNewlines).count)
    }

    private func labeledField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(subtleText)
            TextField(placeholder, text: text)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(fieldBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(fieldBorder, lineWidth: 1)
                        }
                }
        }
    }

    private var legalFooter: some View {
        Text(
            "Revless provides crowdsourced decision support only. Always confirm ZED and standby policies with your airline's official portals before travel."
        )
        .font(.caption2)
        .foregroundStyle(subtleText)
        .multilineTextAlignment(.leading)
        .padding(.top, 12)
    }

    @MainActor
    private func reload() async {
        isLoading = true
        actionError = nil
        defer { isLoading = false }

        await auth.refreshCurrentUser()
        if auth.currentUser?.tenantId != nil { return }

        do {
            latestRequest = try await NetworkManager.shared.getMyTenantRequest()
        } catch let error as NetworkError {
            actionError = error.errorDescription
        } catch {
            actionError = error.localizedDescription
        }
    }

    @MainActor
    private func submitRequest() async {
        actionError = nil
        let name = airlineName.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = airlineCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let msg = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= 2, (2...3).contains(code.count) else {
            actionError = "Enter your airline name and a 2–3 character IATA code."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            latestRequest = try await NetworkManager.shared.createTenantRequest(
                airlineName: name,
                airlineCode: code,
                message: msg.isEmpty ? nil : msg
            )
            airlineName = ""
            airlineCode = ""
            notes = ""
        } catch let error as NetworkError {
            actionError = error.errorDescription
        } catch {
            actionError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        TenantRequestGateView()
            .environment(AuthViewModel())
    }
}
