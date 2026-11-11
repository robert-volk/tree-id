import SwiftUI
import SwiftData

struct IdentifyView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("plantnetKey") private var apiKey = ""

    enum Phase {
        case idle
        case loading
        case done([Candidate])
        case failed(String)
    }

    @State private var organ: Organ = .leaf
    @State private var image: UIImage?
    @State private var phase: Phase = .idle
    @State private var showKey = false
    @State private var saved = false

    private var needsKey: Bool { !Identifier.hasLocalModel && apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Photo of", selection: $organ) {
                    ForEach(Organ.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 0.5))
                } else {
                    FieldCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(organ == .leaf ? "Photograph one leaf" : "Photograph the bark")
                                .font(.serif(17))
                            Text(organ == .leaf
                                 ? "Lay a single leaf flat on a plain background. Fill the frame and keep it in focus."
                                 : "Get close to the trunk at chest height. Fill the frame with bark and avoid moss or shadows.")
                                .font(.serif(14))
                                .foregroundStyle(Theme.ink.opacity(0.75))
                        }
                    }
                }

                PhotoSourceBar { picked in
                    image = picked
                    run()
                }

                if needsKey { keyPrompt }
                result
            }
            .padding(16)
        }
        .paper()
        .navigationTitle("Identify a tree")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !Identifier.hasLocalModel {
                    Button { showKey = true } label: { Image(systemName: "key") }
                        .accessibilityLabel("Pl@ntNet key")
                }
            }
        }
        .sheet(isPresented: $showKey) { KeySheet() }
        .onChange(of: organ) { _, _ in if image != nil { run() } }
    }

    private var keyPrompt: some View {
        FieldCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("One-time setup").font(.serif(16))
                Text("Species matching uses Pl@ntNet's free service. Add your free key to start identifying.")
                    .font(.serif(14))
                Button("Add Pl@ntNet key") { showKey = true }
                    .buttonStyle(FieldButtonStyle(filled: false))
            }
        }
    }

    @ViewBuilder
    private var result: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Looking closely…").font(.serif(15, italic: true))
            }
            .padding(.top, 8)
        case .failed(let message):
            FieldCard {
                Text(message).font(.serif(15))
            }
        case .done(let list):
            if let top = list.first {
                resultCard(top: top, others: Array(list.dropFirst()))
            }
        }
    }

    private func resultCard(top: Candidate, others: [Candidate]) -> some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(top.displayName).font(.serif(28)).multilineTextAlignment(.center)
                if !top.scientific.isEmpty {
                    Text(top.scientific).font(.serif(15, italic: true)).opacity(0.7)
                }
                Text("\(Int((top.score * 100).rounded()))% match")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.paper)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Theme.green, in: Capsule())
            }
            .frame(maxWidth: .infinity)

            if let fact = TreeFacts.lookup(scientific: top.scientific) {
                FieldCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(fact.type) · \(fact.size)").font(.serif(14)).opacity(0.7)
                        Text(fact.note).font(.serif(15))
                    }
                }
            }

            if !others.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("COULD ALSO BE").font(.system(size: 11)).tracking(1).opacity(0.6)
                    ForEach(others) { c in
                        HStack {
                            Text(c.displayName).font(.serif(15))
                            Spacer()
                            Text("\(Int((c.score * 100).rounded()))%").font(.serif(14)).opacity(0.6)
                        }
                        Divider().overlay(Theme.line)
                    }
                }
            }

            Button {
                save(top)
            } label: {
                Label(saved ? "Saved to journal" : "Save to journal", systemImage: saved ? "checkmark" : "book")
            }
            .buttonStyle(FieldButtonStyle(filled: !saved))
        }
    }

    private func run() {
        guard let image else { return }
        saved = false
        if needsKey {
            phase = .idle
            return
        }
        phase = .loading
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        let chosen = organ
        Task {
            do {
                let list = try await Identifier.identify(image: image, organ: chosen, apiKey: key.isEmpty ? nil : key)
                phase = .done(list)
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private func save(_ top: Candidate) {
        guard !saved else { return }
        let entry = Entry(
            kind: "species",
            title: top.displayName,
            subtitle: top.scientific,
            detail: "\(organ.label) photo · \(Int((top.score * 100).rounded()))% match",
            photo: image?.jpeg(maxSide: 600, quality: 0.7)
        )
        context.insert(entry)
        saved = true
    }
}

struct KeySheet: View {
    @AppStorage("plantnetKey") private var apiKey = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Pl@ntNet key").font(.serif(22))
                    Text("Tree ID sends your leaf or bark photo to Pl@ntNet to find the species. The key is free and stays on this phone.")
                        .font(.serif(15))
                    SecureField("Paste your key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
                    Link("Get a free key at my.plantnet.org", destination: URL(string: "https://my.plantnet.org")!)
                        .font(.serif(15))
                    Text("Want fully offline matching? Drop a Core ML model named TreeSpecies into Resources/Models and rebuild. It takes over automatically and no photo leaves the phone.")
                        .font(.serif(13))
                        .opacity(0.7)
                }
                .padding(16)
            }
            .paper()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
