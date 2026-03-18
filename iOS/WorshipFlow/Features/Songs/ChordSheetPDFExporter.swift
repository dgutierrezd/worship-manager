import SwiftUI
import UIKit

// MARK: - PDF Exporter

/// Converts a ChordSheet + Song metadata into a paginated PDF file stored in the temp directory.
/// Uses ImageRenderer (iOS 16+) to render a SwiftUI print-friendly layout, then tiles it across
/// US Letter pages using UIGraphicsPDFRenderer.
enum ChordSheetPDFExporter {

    // US Letter in points (72 pt = 1 inch)
    private static let pageWidth:  CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin:     CGFloat = 48

    /// Renders the chord sheet to a PDF and writes it to a temp file.
    /// Returns the file URL, or nil if rendering failed.
    @MainActor
    static func makePDF(
        sheet: ChordSheet,
        song: Song,
        transposedKey: String?
    ) -> URL? {
        guard let progression = ChordProgression.from(json: sheet.content),
              !progression.sections.isEmpty else { return nil }

        let contentWidth = pageWidth - margin * 2

        // Render the SwiftUI content view to a UIImage at 2× scale for crisp output
        let renderer = ImageRenderer(
            content: ChordSheetPDFContentView(
                sheet: sheet,
                song: song,
                progression: progression,
                transposedKey: transposedKey
            )
            .frame(width: contentWidth)
            .background(Color.white)
        )
        renderer.scale = 2.0

        guard let uiImage = renderer.uiImage else { return nil }

        // Image dimensions in PDF points (divide by scale)
        let imageHeight   = uiImage.size.height / renderer.scale
        let contentHeight = pageHeight - margin * 2
        let pageRect      = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        // Tile the image across as many pages as needed
        let pdfData = UIGraphicsPDFRenderer(bounds: pageRect).pdfData { ctx in
            var yOffset: CGFloat = 0
            while yOffset < imageHeight {
                ctx.beginPage()

                let sliceHeight = min(contentHeight, imageHeight - yOffset)
                let destRect = CGRect(x: margin, y: margin,
                                      width: contentWidth, height: sliceHeight)

                // Clip to the destination rect, then draw the image shifted upward
                // so the current slice lands exactly in the content area
                ctx.cgContext.saveGState()
                ctx.cgContext.clip(to: destRect)
                uiImage.draw(in: CGRect(x: margin, y: margin - yOffset,
                                        width: contentWidth, height: imageHeight))
                ctx.cgContext.restoreGState()

                yOffset += contentHeight
            }
        }

        // Build a safe filename from song title + sheet title
        let safeName = "\(song.title) — \(sheet.title)"
            .components(separatedBy: CharacterSet(charactersIn: "/\\:*?\"<>|"))
            .joined(separator: "-")

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).pdf")

        do {
            try pdfData.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - PDF Content View

/// Print-friendly SwiftUI layout used exclusively for PDF rendering.
/// Uses grayscale shading (no color) so the PDF prints well on B&W printers.
struct ChordSheetPDFContentView: View {
    let sheet: ChordSheet
    let song: Song
    let progression: ChordProgression
    let transposedKey: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Rectangle()
                .fill(Color.black)
                .frame(height: 0.75)
                .padding(.top, 12)
                .padding(.bottom, 10)
            legend
                .padding(.bottom, 18)
            ForEach(progression.sections) { section in
                sectionBlock(section)
                    .padding(.bottom, 18)
            }
            Spacer(minLength: 16)
            footer
        }
        .padding(0)
        .background(Color.white)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(song.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)

                if let artist = song.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.45))
                }

                HStack(spacing: 6) {
                    if let key = transposedKey {
                        metaChip("♪  Key of \(key)")
                    }
                    if let bpm = song.tempoBpm {
                        metaChip("\(bpm) BPM")
                    }
                    if let inst = sheet.instrument, !inst.isEmpty {
                        metaChip(inst)
                    }
                }
                .padding(.top, 2)

                Text(sheet.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(white: 0.4))
                    .padding(.top, 1)
            }

            Spacer()

            Text("WorshipFlow")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(white: 0.6))
        }
    }

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(Color(white: 0.3))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(white: 0.92))
            .clipShape(Capsule())
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(shade: shadeFor(.tonic),       label: "Tonic  (I, iii, vi)")
            legendItem(shade: shadeFor(.subdominant), label: "Sub-dominant  (ii, IV)")
            legendItem(shade: shadeFor(.dominant),    label: "Dominant  (V, vii°)")
        }
    }

    private func legendItem(shade: Double, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: shade))
                .frame(width: 14, height: 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                )
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(Color(white: 0.5))
        }
    }

    // MARK: - Section Block

    private func sectionBlock(_ section: ChordSection) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            // Section label with accent bar
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 3, height: 12)
                    .clipShape(Capsule())
                Text(section.name.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .tracking(1.8)
            }

            let slots = buildBeatSlots(from: section.chords)
            let bars  = stride(from: 0, to: slots.count, by: 4).map {
                Array(slots[$0..<min($0 + 4, slots.count)])
            }

            ForEach(bars.indices, id: \.self) { barIdx in
                HStack(spacing: 4) {
                    Text("\(barIdx + 1)")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(white: 0.55))
                        .frame(width: 12)

                    HStack(spacing: 4) {
                        ForEach(bars[barIdx].indices, id: \.self) { slotIdx in
                            pdfBeatSlot(bars[barIdx][slotIdx])
                        }
                        // Empty beat placeholders to complete 4 beats
                        ForEach(bars[barIdx].count..<4, id: \.self) { _ in
                            emptyTile
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pdfBeatSlot(_ slot: [ChordEntry]) -> some View {
        if slot.count == 2 {
            HStack(spacing: 3) {
                pdfHalfTile(slot[0])
                pdfHalfTile(slot[1])
            }
        } else if slot[0].isPass {
            HStack(spacing: 3) {
                pdfHalfTile(slot[0])
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
        } else {
            pdfFullTile(slot[0])
        }
    }

    private func pdfFullTile(_ chord: ChordEntry) -> some View {
        VStack(spacing: 2) {
            Text(chord.romanNumeral)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            Text(chord.chordName(inKey: transposedKey))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(Color(white: 0.3))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color(white: shadeFor(chord.harmonicFunction)))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(chord.isPass ? 0.08 : 0.18), lineWidth: 0.75)
        )
    }

    private func pdfHalfTile(_ chord: ChordEntry) -> some View {
        VStack(spacing: 1) {
            Text(chord.romanNumeral)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            Text(chord.chordName(inKey: transposedKey))
                .font(.system(size: 7, weight: .semibold, design: .rounded))
                .foregroundColor(Color(white: 0.35))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color(white: shadeFor(chord.harmonicFunction)))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.black.opacity(0.12),
                        style: StrokeStyle(lineWidth: 0.75, dash: [4]))
        )
    }

    private var emptyTile: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(white: 0.97))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black.opacity(0.07),
                            style: StrokeStyle(lineWidth: 0.5, dash: [4]))
            )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Text("Generated by WorshipFlow")
                .font(.system(size: 8))
                .foregroundColor(Color(white: 0.65))
        }
    }

    // MARK: - Helpers

    /// Grayscale shading for each harmonic function — prints well on B&W printers.
    private func shadeFor(_ fn: HarmonicFunction) -> Double {
        switch fn {
        case .tonic:       return 0.90  // light gray
        case .subdominant: return 0.95  // very light gray
        case .dominant:    return 0.84  // slightly darker gray
        }
    }

    private func buildBeatSlots(from chords: [ChordEntry]) -> [[ChordEntry]] {
        var slots: [[ChordEntry]] = []
        var i = 0
        while i < chords.count {
            if chords[i].isPass {
                var slot = [chords[i]]
                if i + 1 < chords.count && chords[i + 1].isPass {
                    slot.append(chords[i + 1])
                    i += 2
                } else {
                    i += 1
                }
                slots.append(slot)
            } else {
                slots.append([chords[i]])
                i += 1
            }
        }
        return slots
    }
}
