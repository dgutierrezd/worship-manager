import SwiftUI

// MARK: - Chords Editor View

struct ChordsEditorView: View {
    let songId: String
    let songKey: String?        // pass song.defaultKey so degree bar shows real chord names
    let chordSheet: ChordSheet?
    @ObservedObject var vm: SongsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var progression = ChordProgression()
    @State private var title = "Chord Sheet"
    @State private var selectedInstrument = ""
    @State private var showSectionPicker = false
    @State private var isLoading = false

    private let instruments = ["", "Guitar", "Piano", "Bass", "Drums", "Keys", "Strings"]
    private let modifiers   = ["", "2", "sus2", "sus4", "add9", "6", "7", "maj7", "m7", "dim", "aug"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Key reference bar
                    if let key = songKey {
                        keyReferenceBar(key)
                    }

                    // Instrument selector
                    instrumentPicker

                    // Sections
                    if progression.sections.isEmpty {
                        emptySectionsView
                    } else {
                        ForEach(progression.sections) { section in
                            sectionCard(section)
                        }
                    }

                    // Add section CTA
                    addSectionButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.appBackground)
            .navigationTitle(chordSheet == nil ? "New Chord Sheet" : "Edit Chords")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView().tint(.appAccent)
                    } else {
                        Button("Save") { Task { await save() } }
                            .fontWeight(.semibold)
                            .foregroundColor(.appAccent)
                            .disabled(progression.sections.isEmpty)
                    }
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

    // MARK: - Key Reference Bar

    private func keyReferenceBar(_ key: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appAccent)
                Text("Key of \(key)  ·  Diatonic Chords")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appSecondary)
                    .tracking(0.3)
            }

            HStack(spacing: 5) {
                ForEach(1...7, id: \.self) { deg in
                    let entry = ChordEntry(degree: deg)
                    let color = functionColor(entry.harmonicFunction)
                    VStack(spacing: 3) {
                        Text(entry.romanNumeral)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(color)
                        Text(entry.chordName(inKey: key))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.appPrimary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(color.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
                }
            }

            // Function legend
            HStack(spacing: 18) {
                legendDot(color: functionColor(.tonic),       label: "Tonic")
                legendDot(color: functionColor(.subdominant), label: "Subdominant")
                legendDot(color: functionColor(.dominant),    label: "Dominant")
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appDivider, lineWidth: 1))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.appSecondary)
        }
    }

    // MARK: - Section Card

    private func sectionCard(_ section: ChordSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label(section.name.uppercased(), systemImage: sectionIcon(section.name))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.appAccent)
                    .tracking(1.2)
                Spacer()
                Button {
                    withAnimation { progression.sections.removeAll { $0.id == section.id } }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.statusNo.opacity(0.5))
                }
            }

            // Chords in measure groups (4 per bar)
            if section.chords.isEmpty {
                Text("Tap a chord below to add it to this section")
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
                    .italic()
                    .padding(.vertical, 4)
            } else {
                measuresView(section: section)
            }

            Divider()

            // Degree bar to add more chords
            degreeBar(sectionId: section.id)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Measures View (4 chords per bar = 4/4 time)

    private func measuresView(section: ChordSection) -> some View {
        let chords = section.chords
        let bars = stride(from: 0, to: chords.count, by: 4).map {
            Array(chords[$0..<min($0 + 4, chords.count)])
        }

        return VStack(alignment: .leading, spacing: 6) {
            ForEach(bars.indices, id: \.self) { barIdx in
                HStack(spacing: 4) {
                    // Bar number
                    Text("\(barIdx + 1)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.appSecondary)
                        .frame(width: 14)

                    // Chord tiles — fill exactly 4 slots
                    HStack(spacing: 5) {
                        ForEach(bars[barIdx]) { chord in
                            chordTile(chord, sectionId: section.id)
                        }
                        // Empty beat placeholders — match tile height
                        ForEach(bars[barIdx].count..<4, id: \.self) { _ in
                            emptyBeatTile
                        }
                    }
                }
            }
        }
    }

    private var emptyBeatTile: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.appBackground)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appDivider.opacity(0.35),
                            style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
    }

    // MARK: - Chord Tile

    private func chordTile(_ chord: ChordEntry, sectionId: UUID) -> some View {
        let fnColor = functionColor(chord.harmonicFunction)
        let isPass = chord.isPass

        return Button {
            withAnimation(.spring(response: 0.2)) {
                togglePass(sectionId: sectionId, chordId: chord.id)
            }
        } label: {
            VStack(spacing: 0) {
                // ── Top: Roman numeral ───────────────────────
                Text(chord.romanNumeral)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isPass ? fnColor.opacity(0.55) : fnColor)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                Spacer()

                // ── Centre: Chord name (NOTE) ────────────────
                Text(chord.chordName(inKey: songKey))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(isPass ? .appSecondary : .white)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .padding(.horizontal, 4)

                Spacer()

                // ── Bottom: Nashville degree + modifier ──────
                HStack(spacing: 2) {
                    Text("\(chord.degree)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    if let mod = chord.modifier, !mod.isEmpty {
                        Text(mod).font(.system(size: 9, weight: .medium))
                    } else if isPass {
                        Text("PASS").font(.system(size: 8, weight: .bold))
                    }
                }
                .foregroundColor(isPass ? .appSecondary.opacity(0.7) : .white.opacity(0.65))
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background {
                if isPass {
                    Color.appSurface
                } else {
                    LinearGradient(
                        colors: [fnColor, fnColor.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPass ? fnColor.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: isPass ? .clear : fnColor.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .contextMenu {
            // Modifier submenu
            Menu {
                ForEach(modifiers, id: \.self) { mod in
                    Button {
                        setModifier(sectionId: sectionId, chordId: chord.id,
                                    modifier: mod.isEmpty ? nil : mod)
                    } label: {
                        HStack {
                            Text(mod.isEmpty ? "None" : mod)
                            if (chord.modifier ?? "") == mod ||
                               (mod.isEmpty && chord.modifier == nil) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Modifier", systemImage: "textformat.subscript")
            }

            Divider()

            Button(isPass ? "Mark as Full Beat" : "Mark as Passing Chord") {
                togglePass(sectionId: sectionId, chordId: chord.id)
            }

            Divider()

            Button(role: .destructive) {
                deleteChord(fromSection: sectionId, chordId: chord.id)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    // MARK: - Degree Bar (keyboard to add chords)

    private func degreeBar(sectionId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD CHORD  ·  TAP TO INSERT")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.appSecondary)
                .tracking(1.2)

            HStack(spacing: 5) {
                ForEach(1...7, id: \.self) { degree in
                    let entry = ChordEntry(degree: degree)
                    let color = functionColor(entry.harmonicFunction)

                    Button {
                        addChord(toSection: sectionId, degree: degree)
                    } label: {
                        VStack(spacing: 3) {
                            Text(entry.romanNumeral)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(color)
                            Text(songKey != nil
                                 ? entry.chordName(inKey: songKey)
                                 : "\(degree)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.appPrimary)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(color.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(color.opacity(0.28), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Instrument Picker

    private var instrumentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(instruments, id: \.self) { inst in
                    Button { selectedInstrument = inst } label: {
                        Text(inst.isEmpty ? "All Instruments" : inst)
                            .font(.appCaption)
                            .foregroundColor(selectedInstrument == inst ? .white : .appPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedInstrument == inst ? Color.appPrimary : Color.appSurface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.appDivider,
                                                     lineWidth: selectedInstrument == inst ? 0 : 1))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptySectionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44))
                .foregroundColor(.appDivider)
            Text("No Sections Yet")
                .font(.appHeadline)
                .foregroundColor(.appSecondary)
            Text("Tap \"Add Section\" to start building\nyour chord progression")
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }

    // MARK: - Add Section Button

    private var addSectionButton: some View {
        Button { showSectionPicker = true } label: {
            HStack(spacing: 8) {
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
                    .stroke(Color.appAccent.opacity(0.35),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
    }

    // MARK: - Harmonic Function Colors

    func functionColor(_ fn: HarmonicFunction) -> Color {
        switch fn {
        case .tonic:       return Color(hex: "#3B82F6") // Blue  — home/stable
        case .subdominant: return Color(hex: "#10B981") // Green — movement
        case .dominant:    return Color(hex: "#F59E0B") // Amber — tension
        }
    }

    // MARK: - Section Icon

    private func sectionIcon(_ name: String) -> String {
        switch name.lowercased() {
        case "intro":          return "play.circle"
        case "verse":          return "text.alignleft"
        case "pre-chorus":     return "arrow.up.right"
        case "chorus":         return "waveform.path.ecg"
        case "bridge":         return "arrow.triangle.swap"
        case "instrumental":   return "guitars"
        case "outro":          return "stop.circle"
        case "tag":            return "repeat"
        default:               return "music.note"
        }
    }

    // MARK: - Mutations

    private func addChord(toSection sectionId: UUID, degree: Int) {
        guard let idx = progression.sections.firstIndex(where: { $0.id == sectionId }) else { return }
        withAnimation(.spring(response: 0.3)) {
            progression.sections[idx].chords.append(ChordEntry(degree: degree))
        }
    }

    private func setModifier(sectionId: UUID, chordId: UUID, modifier: String?) {
        guard let si = progression.sections.firstIndex(where: { $0.id == sectionId }),
              let ci = progression.sections[si].chords.firstIndex(where: { $0.id == chordId })
        else { return }
        progression.sections[si].chords[ci].modifier = modifier
    }

    private func togglePass(sectionId: UUID, chordId: UUID) {
        guard let si = progression.sections.firstIndex(where: { $0.id == sectionId }),
              let ci = progression.sections[si].chords.firstIndex(where: { $0.id == chordId })
        else { return }
        progression.sections[si].chords[ci].isPass.toggle()
    }

    private func deleteChord(fromSection sectionId: UUID, chordId: UUID) {
        guard let si = progression.sections.firstIndex(where: { $0.id == sectionId }) else { return }
        withAnimation {
            progression.sections[si].chords.removeAll { $0.id == chordId }
        }
    }

    // MARK: - Load / Save

    private func loadExisting() {
        guard let sheet = chordSheet else { return }
        if let parsed = ChordProgression.from(json: sheet.content) {
            progression = parsed
        }
        title = sheet.title
        selectedInstrument = sheet.instrument ?? ""
    }

    private func save() async {
        isLoading = true
        let success = await vm.saveChordSheet(
            songId: songId,
            chordId: chordSheet?.id,
            instrument: selectedInstrument.isEmpty ? nil : selectedInstrument,
            title: title,
            content: progression.toJSON()
        )
        isLoading = false
        if success { dismiss() }
    }
}
