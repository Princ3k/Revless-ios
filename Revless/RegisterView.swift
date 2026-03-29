// RegisterView.swift
// Revless
//
// New-account creation screen.
// Same Aero-Glass dark aesthetic as LoginView.
// On success the ViewModel auto-logs the user in so they land
// directly in the app without any extra tap.

import SwiftUI

struct RegisterView: View {

    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email:           String = ""
    @State private var password:        String = ""
    @State private var confirmPassword: String = ""
    @FocusState private var focus: Field?

    private enum Field { case email, password, confirm }

    // MARK: - Palette (mirrors LoginView)

    private let bg = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.06, blue: 0.14),
            Color(red: 0.07, green: 0.07, blue: 0.11),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.38, green: 0.44, blue: 0.98),
            Color(red: 0.55, green: 0.28, blue: 0.92),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    private let fieldBackground = Color.white.opacity(0.07)
    private let fieldBorder      = Color.white.opacity(0.12)
    private let subtleText       = Color.white.opacity(0.45)
    private let accentBlue       = Color(red: 0.38, green: 0.44, blue: 0.98)

    // MARK: - Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 64)

                    Spacer().frame(height: 48)

                    formCard
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 28)

                    signInLink
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Sign In")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(accentBlue)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(ctaGradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: accentBlue.opacity(0.5), radius: 20, y: 8)
                Image(systemName: "airplane.departure")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Create Account")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Use your airline work email to get started.")
                .font(.subheadline)
                .foregroundStyle(subtleText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(spacing: 14) {
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

            inputField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password,
                field: .password,
                contentType: .newPassword,
                keyboard: .default,
                isSecure: true
            )

            inputField(
                icon: "lock.rotation",
                placeholder: "Confirm password",
                text: $confirmPassword,
                field: .confirm,
                contentType: .newPassword,
                keyboard: .default,
                isSecure: true
            )

            passwordStrengthBar

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

            // CTA
            Button {
                focus = nil
                Task {
                    await auth.register(
                        email: email,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ctaGradient)
                        .shadow(color: accentBlue.opacity(0.4), radius: 16, y: 6)

                    if auth.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 54)
            }
            .disabled(auth.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: auth.isLoading)
        }
    }

    // MARK: - Password strength bar

    private var passwordStrengthBar: some View {
        let strength = passwordStrength(password)
        return VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(strength.color)
                        .frame(width: geo.size.width * strength.fraction, height: 3)
                        .animation(.spring(response: 0.4), value: password)
                }
            }
            .frame(height: 3)

            Text(strength.label)
                .font(.caption2)
                .foregroundStyle(strength.color)
                .animation(.easeInOut, value: password)
        }
        .opacity(password.isEmpty ? 0 : 1)
    }

    // MARK: - Sign-in link

    private var signInLink: some View {
        Button { dismiss() } label: {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(subtleText)
                Text("Sign In")
                    .foregroundStyle(accentBlue)
                    .fontWeight(.semibold)
            }
            .font(.footnote)
        }
    }

    // MARK: - Input field builder (mirrors LoginView)

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
                .foregroundStyle(focus == field ? accentBlue : subtleText)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.15), value: focus)

            if isSecure {
                SecureField(placeholder, text: text)
                    .focused($focus, equals: field)
                    .textContentType(contentType)
                    .submitLabel(field == .confirm ? .done : .next)
                    .onSubmit {
                        if field == .password { focus = .confirm }
                        else if field == .confirm {
                            focus = nil
                            Task {
                                await auth.register(
                                    email: email,
                                    password: password,
                                    confirmPassword: confirmPassword
                                )
                            }
                        }
                    }
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
                            focus == field ? accentBlue.opacity(0.6) : fieldBorder,
                            lineWidth: 1
                        )
                }
        }
        .animation(.easeInOut(duration: 0.15), value: focus)
    }

    // MARK: - Helpers

    private struct PasswordStrength {
        let label: String
        let fraction: CGFloat
        let color: Color
    }

    private func passwordStrength(_ pw: String) -> PasswordStrength {
        let n = pw.count
        switch n {
        case 0..<8:  return PasswordStrength(label: "Too short",  fraction: 0.25, color: .red)
        case 8..<12: return PasswordStrength(label: "Fair",       fraction: 0.50, color: .orange)
        case 12..<16:return PasswordStrength(label: "Good",       fraction: 0.75, color: .yellow)
        default:     return PasswordStrength(label: "Strong",     fraction: 1.00, color: Color(red: 0.3, green: 0.85, blue: 0.55))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RegisterView()
            .environment(AuthViewModel())
    }
}
