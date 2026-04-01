// Models.swift
// Revless
//
// Codable structs that mirror the backend Pydantic schemas exactly.
// JSONDecoder is configured with .convertFromSnakeCase so snake_case
// JSON keys map automatically to camelCase Swift properties.

import Foundation

// MARK: - Auth

struct LoginResponse: Codable {
    let accessToken: String   // "access_token"
    let tokenType: String     // "bearer"
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
}

// MARK: - User

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let tenantId: UUID?
    var searchCredits: Int
}

// MARK: - Tenant request (self-service airline onboarding)

enum TenantRequestStatus: String, Codable {
    case pending
    case approved
    case rejected
}

struct TenantRequestRead: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let emailDomain: String
    let airlineName: String
    let airlineCode: String
    let message: String?
    let status: TenantRequestStatus
    let createdAt: String
    let resolvedAt: String?
    let adminNote: String?
}

// MARK: - Enums (match backend Python enums exactly)

enum TravelerType: String, Codable, CaseIterable, Identifiable {
    case employee
    case spouse
    case companion
    case parent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .employee:  return "Employee"
        case .spouse:    return "Spouse"
        case .companion: return "Companion (Unaccompanied)"
        case .parent:    return "Parent"
        }
    }
}

enum ZedTier: String, Codable {
    case low
    case medium
    case high

    var displayName: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .low:    return "zedLow"
        case .medium: return "zedMedium"
        case .high:   return "zedHigh"
        }
    }
}

// MARK: - Flight Search

struct FlightLeg: Codable, Hashable {
    let carrierIata: String     // "TK"
    let carrierName: String     // "Turkish Airlines"
    let origin: String          // "YYZ"
    let destination: String     // "IST"
    let departureTime: String   // "2026-05-11T23:00:00"
    let arrivalTime: String     // "2026-05-12T17:00:00"
    let durationMinutes: Int

    /// Formatted layover duration, e.g. "10h 0m"
    var durationFormatted: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

/// An agreement rule that needs crowd-verification.
/// Returned by /search/routes when confidence_score < 3.
/// Contains the rule_id the VerificationModal needs to call /agreements/verify.
struct StaleRule: Codable, Identifiable {
    let ruleId: UUID        // pass this to POST /agreements/verify
    let carrierIata: String
    let carrierName: String
    let confidenceScore: Int

    var id: UUID { ruleId }
}

struct Itinerary: Codable, Identifiable {
    let legs: [FlightLeg]
    let totalDurationMinutes: Int
    let totalZedTier: ZedTier
    let requiresVerification: Bool
    let staleRules: [StaleRule]
    /// 0.0–1.0 heuristic standby outlook (not live load-factor data).
    let boardingProbability: Double

    /// Synthetic stable ID derived from the carrier path
    var id: String {
        legs.map { "\($0.carrierIata)\($0.origin)\($0.destination)" }.joined(separator: "-")
    }

    /// Human-readable carrier path: "YYZ → IST → KUL"
    var routeSummary: String {
        var airports = legs.map(\.origin)
        if let last = legs.last { airports.append(last.destination) }
        return airports.joined(separator: " → ")
    }

    /// Total trip duration string
    var totalDurationFormatted: String {
        let h = totalDurationMinutes / 60
        let m = totalDurationMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

struct RouteSearchResponse: Codable {
    let origin: String
    let destination: String
    let date: String
    let travelerType: TravelerType
    let itineraries: [Itinerary]
    let totalRaw: Int
    let totalFiltered: Int
}

// MARK: - Agreement Verification

struct AgreementVerificationRequest: Codable {
    let ruleId: UUID
    let isAccurate: Bool
}

struct AgreementVerificationResponse: Codable {
    let ruleId: UUID
    let isAccurate: Bool
    let confidenceScore: Int
    let lastVerified: String
    let userSearchCredits: Int
}

// MARK: - Search history (GET /search/history)

struct SearchHistoryItem: Codable, Identifiable {
    let id: UUID
    let origin: String
    let destination: String
    let travelDate: String
    let travelerType: TravelerType
    let totalRaw: Int
    let totalFiltered: Int
    /// ISO-8601 from API
    let createdAt: String

    var routeLabel: String { "\(origin) → \(destination)" }

    var resultSummary: String {
        guard totalRaw > 0 else { return "No routes returned" }
        let dropped = totalRaw - totalFiltered
        if dropped == 0 {
            return "\(totalFiltered) route\(totalFiltered == 1 ? "" : "s") eligible"
        }
        return "\(totalFiltered) of \(totalRaw) eligible · \(dropped) filtered"
    }

    var departureDisplay: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = parser.date(from: travelDate) else { return travelDate }
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        out.locale = Locale(identifier: "en_US_POSIX")
        return out.string(from: date)
    }

    var searchedAtDate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: createdAt) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: createdAt)
    }
}

// MARK: - Verification history (GET /auth/me/verifications)

struct VerificationHistoryItem: Codable, Identifiable {
    let id: UUID
    let ruleId: UUID
    let carrierIata: String
    let carrierName: String
    let isAccurate: Bool
    let createdAt: String

    var createdAtDate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: createdAt) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: createdAt)
    }
}

// MARK: - Agreement matrix & peer-reviewed documents

struct MatrixRuleRow: Codable, Identifiable, Hashable {
    var id: UUID { ruleId }
    let ruleId: UUID
    let carrierIata: String
    let carrierName: String
    let travelerType: TravelerType
    let zedTier: ZedTier
    let isUnaccompaniedAllowed: Bool
    let confidenceScore: Int
    let isVerified: Bool
    let isStale: Bool
}

struct PendingDocumentSummary: Codable, Identifiable, Hashable {
    let id: UUID
    let carrierIata: String
    let carrierName: String
    let approvalCount: Int
    let requiredApprovals: Int
    let status: String
    let createdAt: String
    let uploaderEmail: String

    var createdAtDate: Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: createdAt) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: createdAt)
    }
}

struct AgreementMatrixResponse: Codable {
    let rules: [MatrixRuleRow]
    let pendingDocuments: [PendingDocumentSummary]
}

struct AgreementDocumentUploadResponse: Codable {
    let documentId: UUID
    let status: String
    let carrierIata: String
}

struct DocumentApproveResponse: Codable {
    let documentId: UUID
    let approvalCount: Int
    let requiredApprovals: Int
    let status: String
    let documentNowOfficial: Bool
    let userSearchCredits: Int
}
