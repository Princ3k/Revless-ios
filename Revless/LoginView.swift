// LoginView.swift
// Revless
//
// Premium dark-mode login screen.
// Palette: deep midnight navy background, indigo-violet CTA gradient,
// frosted-glass input fields, SF Pro Rounded wordmark.

import SwiftUI

struct LoginView: View {

    @Environment(AuthViewModel.self) private var auth

    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    // MARK: - Palette

    private let bg = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.06, blue: 0.14),   // deep midnight navy
            Color(red: 0.07, green: 0.07, blue: 0.11),   // dark charcoal
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.38, green: 0.44, blue: 0.98),   // electric indigo
            Color(red: 0.55, green: 0.28, blue: 0.92),   // deep violet
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private let fieldBackground = Color.white.opacity(0.07)
    private let fieldBorder      = Color.white.opacity(0.12)
    private let subtleText       = Color.white.opacity(0.45)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        brandMark
                            .padding(.top, 80)

                        Spacer().frame(height: 56)

                        formCard
                            .padding(.horizontal, 24)

                        Spacer().frame(height: 32)

                        registerLink

                        Spacer().frame(height: 40)
                    }
                    .frame(maxWidth: 480)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .preferredColorScheme(.dark)
            .onDisappear { auth.errorMessage = nil }
        }
    }

    // MARK: - Brand mark

    private var brandMark: some View {
        VStack(spacing: 14) {
            // Logo badge
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ctaGradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color(red: 0.38, green: 0.44, blue: 0.98).opacity(0.5), radius: 20, y: 8)

                Text("R")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Wordmark
            Text("Revless")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("ZED interline travel, simplified.")
                .font(.subheadline)
                .foregroundStyle(subtleText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(spacing: 16) {
            // Email
            inputField(
                icon: "envelope.fill",
                placeholder: "Work email",
                text: $email,
                field: .email,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                isSecure: false
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            // Password
            inputField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password,
                field: .password,
                contentType: .password,
                keyboard: .default,
                isSecure: true
            )

            // Error banner
            if let error = auth.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color.red.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer().frame(height: 4)

            // CTA button
            Button {
                focus = nil
                Task { await auth.login(email: email, password: password) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ctaGradient)
                        .shadow(
                            color: Color(red: 0.38, green: 0.44, blue: 0.98).opacity(0.45),
                            radius: 16, y: 6
                        )

                    if auth.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 54)
            }
            .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: auth.isLoading)
        }
    }

    // MARK: - Input field builder

    @ViewBuilder
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType,
        keyboard: UIKeyboardType,
        isSecure: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(focus == field ? Color(red: 0.55, green: 0.60, blue: 0.98) : subtleText)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.15), value: focus)

            if isSecure {
                SecureField(placeholder, text: text)
                    .focused($focus, equals: field)
                    .textContentType(contentType)
                    .submitLabel(.go)
                    .onSubmit { Task { await auth.login(email: email, password: password) } }
            } else {
                TextField(placeholder, text: text)
                    .focused($focus, equals: field)
                    .textContentType(contentType)
                    .keyboardType(keyboard)
                    .submitLabel(.next)
                    .onSubmit { focus = .password }
            }
        }
        .font(.body)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(fieldBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            focus == field ? Color(red: 0.38, green: 0.44, blue: 0.98).opacity(0.6) : fieldBorder,
                            lineWidth: 1
                        )
                }
        }
        .animation(.easeInOut(duration: 0.15), value: focus)
    }

    // MARK: - Register link

    private var registerLink: some View {
        NavigationLink(destination: RegisterView()) {
            HStack(spacing: 4) {
                Text("New to Revless?")
                    .foregroundStyle(subtleText)
                Text("Create an account")
                    .foregroundStyle(Color(red: 0.38, green: 0.44, blue: 0.98))
                    .fontWeight(.semibold)
            }
            .font(.footnote)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
