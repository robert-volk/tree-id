import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Your pocket field guide")
                        .font(.serif(15, italic: true)).opacity(0.7)

                    NavigationLink { IdentifyView() } label: {
                        tile(icon: "leaf", title: "Identify a tree", sub: "Leaf or bark photo")
                    }
                    NavigationLink { AgeView() } label: {
                        tile(icon: "circle.dashed", title: "Age a stump", sub: "Count the rings")
                    }

                    Text("RECENT FINDS")
                        .font(.system(size: 11)).tracking(1).opacity(0.6)
                        .padding(.top, 10)

                    if entries.isEmpty {
                        Text("Nothing saved yet. Identify a tree or age a stump and save it here.")
                            .font(.serif(14)).opacity(0.7)
                    } else {
                        ForEach(entries) { entry in
                            NavigationLink { EntryDetail(entry: entry) } label: { row(entry) }
                            Divider().overlay(Theme.line)
                        }
                    }
                }
                .padding(16)
            }
            .paper()
            .navigationTitle("Tree ID")
        }
        .tint(Theme.green)
    }

    private func tile(icon: String, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(Theme.green)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.serif(18))
                Text(sub).font(.serif(13)).opacity(0.7)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13)).opacity(0.4)
        }
        .foregroundStyle(Theme.ink)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.green.opacity(0.6), lineWidth: 0.5))
    }

    private func row(_ e: Entry) -> some View {
        HStack(spacing: 12) {
            thumb(e)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(e.title).font(.serif(16))
                Text(e.subtitle.isEmpty ? e.date.formatted(date: .abbreviated, time: .omitted) : e.subtitle)
                    .font(.serif(13, italic: true)).opacity(0.7)
            }
            Spacer()
        }
        .foregroundStyle(Theme.ink)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func thumb(_ e: Entry) -> some View {
        if let data = e.photo, let img = UIImage(data: data) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            Theme.card
        }
    }
}

struct EntryDetail: View {
    let entry: Entry
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let data = entry.photo, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text(entry.title).font(.serif(28)).multilineTextAlignment(.center)
                if !entry.subtitle.isEmpty {
                    Text(entry.subtitle).font(.serif(15, italic: true)).opacity(0.7)
                }
                Text(entry.detail).font(.serif(14))
                Text(entry.date.formatted(date: .long, time: .shortened))
                    .font(.serif(13)).opacity(0.6)

                Button(role: .destructive) {
                    context.delete(entry)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .padding(.top, 10)
            }
            .padding(16)
        }
        .paper()
        .navigationBarTitleDisplayMode(.inline)
    }
}
