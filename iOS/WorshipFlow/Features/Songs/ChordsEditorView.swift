import SwiftUI

struct ChordsEditorView: View {
    let songId: String
    let chordSheet: ChordSheet?
    @ObservedObject var vm: SongsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var progression = ChordProgression()
    @State private var title = "Chord Sheet"
    @State private var selectedInstrument = ""
    @State private var showSectionPicker = false
    @State private var isLoading = false

    private let instruments = ["", "Guitar", "Piano", "Bass", "Drums"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    instrumentPicker

                    ForEach(progression.sections) { section in
                        sectionCard(section)
                    }

                    addSectionButton
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("edit_chords".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(progression.sections.isEmpty || isLoading)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Add Section", isPresented: $showSectionPicker) {
                ForEach(ChordSection.sectionNames, id: \.self) { name in
                    Button(name) {
                        withAnimation(.spring(response: 0.3)) {
                            progression.sections.append(ChordSection(name: name))
                        }
                    }
                }
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Section Card

    private func sectionCard(_ section: ChordSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack {
                Text(section.name.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appAccent)
                    .tracking(1.5)

                Spacer()

                Button { deleteSection(section.id) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.statusNo.opacity(0.6))
                }
            }

            // Chord badges (wrapping flow)
            if !section.chords.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(section.chords) { chord in
                        chordBadge(chord, sectionId: section.id)
                    }
                }
            }

            // Degree bar (1–7) to add chords
            degreeBar(sectionId: section.id)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Chord Badge
    //  Tap to toggle full/pass. Long-press (context menu) to delete.

    private func chordBadge(_ chord: ChordEntry, sectionId: UUID) -> some View {
        Button {
            toggleChord(inSection: sectionId, chordId: chord.id)
        } label: {
            VStack(spacing: 2) {
                Text("\(chord.degree)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text(chord.isPass ? "pass" : "full")
                    .font(.system(size: 9, weight: .semibold))
                    .textCase(.uppercase)
            }
            .foregroundColor(chord.isPass ? .appSecondary : .white)
            .frame(width: 50, height: 54)
            .background(chord.isPass ? Color.appSurface : Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(chord.isPass ? Color.appDivider : Color.clear, lineWidth: 1.5)
            )
        }
        .contextMenu {
            Button(chord.isPass ? "Set Full Comp\u{00E1}s" : "Set Pass") {
                toggleChord(inSection: sectionId, chordId: chord.id)
            }
            Button(role: .destructive) {
                deleteChord(fromSection: sectionId, chordId: chord.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Degree Bar

    private func degreeBar(sectionId: UUID) -> some View {
        HStack(spacing: 0) {
            ForEach(1...7, id: \.self) { degree in
                Button {
                    addChord(toSection: sectionId, degree: degree)
                } label: {
                    Text("\(degree)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.appBackground)
                }

                if degree < 7 {
                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(width: 1, height: 22)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appDivider, lineWidth: 1)
        )
    }

    // MARK: - Instrument Picker

    private var instrumentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(instruments, id: \.self) { inst in
                    Button {
                        selectedInstrument = inst
                    } label: {
                        Text(inst.isEmpty ? "All" : inst)
                            .font(.appCaption)
                            .foregroundColor(selectedInstrument == inst ? .white : .appPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedInstrument == inst ? Color.appPrimary : Color.appSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.appDivider, lineWidth: selectedInstrument == inst ? 0 : 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Add Section Button

    private var addSectionButton: some View {
        Button {
            showSectionPicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("Add Section")
            }
            .font(.appHeadline)
            .foregroundColor(.appAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appAccent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
    }

    // MARK: - Mutations

    private func addChord(toSection sectionId: UUID, degree: Int) {
        if let idx = progression.sections.firstIndex(where: { $0.id == sectionId }) {
            withAnimation(.spring(response: 0.3)) {
                progression.sections[idx].chords.append(ChordEntry(degree: degree))
            }
        }
    }

    private func toggleChord(inSection sectionId: UUID, chordId: UUID) {
        if let si = progression.sections.firstIndex(where: { $0.id == sectionId }),
           let ci = progression.sections[si].chords.firstIndex(where: { $0.id == chordId }) {
            withAnimation(.spring(response: 0.2)) {
                progression.sections[si].chords[ci].isPass.toggle()
            }
        }
    }

    private func deleteChord(fromSection sectionId: UUID, chordId: UUID) {
        if let si = progression.sections.firstIndex(where: { $0.id == sectionId }) {
            withAnimation {
                progression.sections[si].chords.removeAll { $0.id == chordId }
            }
        }
    }

    private func deleteSection(_ sectionId: UUID) {
        withAnimation {
            progression.sections.removeAll { $0.id == sectionId }
        }
    }

    // MARK: - Load / Save

    private func loadExisting() {
        if let sheet = chordSheet {
            if let parsed = ChordProgression.from(json: sheet.content) {
                progression = parsed
            }
            title = sheet.title
            selectedInstrument = sheet.instrument ?? ""
        }
    }

    private func save() async {
        isLoading = true
        let content = progression.toJSON()
        let success = await vm.saveChordSheet(
            songId: songId,
            chordId: chordSheet?.id,
            instrument: selectedInstrument.isEmpty ? nil : selectedInstrument,
            title: title,
            content: content
        )
        isLoading = false
        if success { dismiss() }
    }
}
