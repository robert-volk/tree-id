import Foundation
import UIKit
import Vision
import CoreML

enum Organ: String, CaseIterable, Identifiable {
    case leaf, bark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct Candidate: Identifiable {
    let id = UUID()
    let common: String
    let scientific: String
    let score: Double       // 0...1

    var displayName: String { common.isEmpty ? scientific : common }
}

enum IDError: LocalizedError {
    case noEngine
    case message(String)

    var errorDescription: String? {
        switch self {
        case .noEngine: return "Add a free Pl@ntNet key, or drop a TreeSpecies model into the app, to identify trees."
        case .message(let m): return m
        }
    }
}

/// Species identification.
/// 1. If a Core ML model named `TreeSpecies` was bundled, it runs fully on-device.
/// 2. Otherwise, if the user added a free Pl@ntNet key, the photo is sent to Pl@ntNet.
enum Identifier {
    static var localModelURL: URL? {
        Bundle.main.url(forResource: "TreeSpecies", withExtension: "mlmodelc")
    }

    static var hasLocalModel: Bool { localModelURL != nil }

    static func identify(image: UIImage, organ: Organ, apiKey: String?) async throws -> [Candidate] {
        if let url = localModelURL {
            return try await Task.detached { try runLocal(image: image, modelURL: url) }.value
        }
        guard let apiKey, !apiKey.isEmpty else { throw IDError.noEngine }
        return try await runPlantNet(image: image, organ: organ, apiKey: apiKey)
    }

    // MARK: On-device

    private static func runLocal(image: UIImage, modelURL: URL) throws -> [Candidate] {
        guard let cg = image.cgImage else { throw IDError.message("Couldn't read that photo.") }
        let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop
        try VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
        let obs = (request.results as? [VNClassificationObservation]) ?? []
        return obs.prefix(5).map { o in
            let name = o.identifier.replacingOccurrences(of: "_", with: " ")
            return Candidate(common: name.capitalized, scientific: "", score: Double(o.confidence))
        }
    }

    // MARK: Pl@ntNet

    private static func runPlantNet(image: UIImage, organ: Organ, apiKey: String) async throws -> [Candidate] {
        guard let jpeg = image.jpeg(maxSide: 1024, quality: 0.8) else {
            throw IDError.message("Couldn't read that photo.")
        }
        var comps = URLComponents(string: "https://my-api.plantnet.org/v2/identify/all")!
        comps.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "nb-results", value: "5"),
        ]
        let boundary = "TreeID-\(UUID().uuidString)"
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func add(_ s: String) { body.append(Data(s.utf8)) }
        add("--\(boundary)\r\nContent-Disposition: form-data; name=\"organs\"\r\n\r\n\(organ.rawValue)\r\n")
        add("--\(boundary)\r\nContent-Disposition: form-data; name=\"images\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n")
        body.append(jpeg)
        add("\r\n--\(boundary)--\r\n")
        req.httpBody = body

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw IDError.message("Couldn't reach Pl@ntNet. Check your connection and try again.")
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: break
        case 401, 403: throw IDError.message("Pl@ntNet didn't accept that key. Check it and try again.")
        case 404: throw IDError.message("No match found. Try a clearer, closer photo.")
        case 429: throw IDError.message("Pl@ntNet's daily limit is reached. Try again tomorrow.")
        default: throw IDError.message("Pl@ntNet returned an error (\(status)).")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            throw IDError.message("Couldn't read Pl@ntNet's answer.")
        }
        let list: [Candidate] = results.compactMap { r in
            guard let species = r["species"] as? [String: Any],
                  let sci = species["scientificNameWithoutAuthor"] as? String else { return nil }
            let common = (species["commonNames"] as? [String])?.first ?? ""
            let score = (r["score"] as? Double) ?? 0
            return Candidate(common: common, scientific: sci, score: score)
        }
        if list.isEmpty { throw IDError.message("No match found. Try a clearer, closer photo.") }
        return list
    }
}
