// AgreementMatrixViewModel.swift
// Revless
//
// State for the Agreements tab: matrix fetch, upload, and peer approvals.
// `fetchMatrix()` mirrors the product name used with `SearchViewModel.fetchMatrix()`.

import Foundation
import Observation

@Observable
final class AgreementMatrixViewModel {

    var matrix: AgreementMatrixResponse?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func fetchMatrix() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            matrix = try await NetworkManager.shared.getAgreementMatrix()
        } catch let e as NetworkError {
            errorMessage = e.errorDescription
            matrix = nil
        } catch {
            errorMessage = error.localizedDescription
            matrix = nil
        }
    }

    @MainActor
    func uploadDocument(data: Data, fileName: String, mimeType: String, carrierIata: String) async throws {
        _ = try await NetworkManager.shared.uploadAgreementDocument(
            carrierIata: carrierIata,
            fileData: data,
            fileName: fileName,
            mimeType: mimeType
        )
        await fetchMatrix()
    }

    @MainActor
    func approveDocument(id: UUID) async throws -> DocumentApproveResponse {
        try await NetworkManager.shared.approveAgreementDocument(documentId: id)
    }
}
