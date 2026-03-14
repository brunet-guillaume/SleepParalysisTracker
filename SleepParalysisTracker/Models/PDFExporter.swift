import AppKit
import PDFKit

final class PDFExporter {
    static func export(episodes: [Episode]) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "paralysies-du-sommeil.pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let pageWidth: CGFloat = 595 // A4
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2

        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }

        let sorted = episodes.sorted { $0.date > $1.date }
        var y: CGFloat = 0

        let titleFont = NSFont.boldSystemFont(ofSize: 20)
        let headerFont = NSFont.boldSystemFont(ofSize: 11)
        let bodyFont = NSFont.systemFont(ofSize: 10)
        let smallFont = NSFont.systemFont(ofSize: 9)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current

        func startPage() {
            context.beginPDFPage(nil)
            y = pageHeight - margin
        }

        func checkPageBreak(needed: CGFloat) {
            if y - needed < margin {
                context.endPDFPage()
                startPage()
            }
        }

        func drawText(_ text: String, font: NSFont, color: NSColor = .black, x: CGFloat = margin, maxWidth: CGFloat = contentWidth) -> CGFloat {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSize(width: maxWidth, height: .greatestFiniteMagnitude), nil)
            let textHeight = ceil(suggestedSize.height)

            checkPageBreak(needed: textHeight + 4)

            let textRect = CGRect(x: x, y: y - textHeight, width: maxWidth, height: textHeight)
            let path = CGPath(rect: textRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
            context.saveGState()
            context.textMatrix = .identity
            CTFrameDraw(frame, context)
            context.restoreGState()

            y -= textHeight + 4
            return textHeight
        }

        func drawLine() {
            checkPageBreak(needed: 10)
            context.setStrokeColor(NSColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: margin, y: y))
            context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            context.strokePath()
            y -= 8
        }

        // Start
        startPage()

        // Title
        _ = drawText(String(localized: "menubar.title"), font: titleFont)
        y -= 8

        // Stats summary
        let total = episodes.count
        let withHallucination = episodes.filter(\.hasHallucination).count
        let avgStress = episodes.isEmpty ? 0.0 : Double(episodes.map(\.stressLevel).reduce(0, +)) / Double(total)
        _ = drawText("\(String(localized: "stats.total")): \(total)  |  \(String(localized: "stats.avg_stress")): \(String(format: "%.1f", avgStress))/10  |  \(String(localized: "stats.with_hallucination")): \(withHallucination) (\(total > 0 ? Int(Double(withHallucination) / Double(total) * 100) : 0)%)", font: bodyFont, color: .darkGray)
        y -= 12
        drawLine()
        y -= 4

        // Episodes
        for episode in sorted {
            checkPageBreak(needed: 80)

            // Date + stress
            let dateStr = dateFormatter.string(from: episode.date)
            _ = drawText(dateStr, font: headerFont)

            _ = drawText("\(String(localized: "form.stress")): \(episode.stressLevel)/10", font: bodyFont)

            // Position
            if let pos = episode.sleepPosition {
                _ = drawText("\(String(localized: "form.position")): \(pos.label)", font: smallFont, color: .darkGray)
            }

            // Hallucinations
            if episode.hasHallucination && !episode.hallucinationTypes.isEmpty {
                let types = episode.hallucinationTypes.map(\.label).sorted().joined(separator: ", ")
                _ = drawText("\(String(localized: "form.hallucination")): \(types)", font: smallFont, color: NSColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1))
            }

            // Triggers
            if !episode.triggers.isEmpty {
                let triggers = episode.triggers.map(\.label).sorted().joined(separator: ", ")
                _ = drawText("\(String(localized: "form.triggers")): \(triggers)", font: smallFont, color: .darkGray)
            }

            // Notes
            if !episode.notes.isEmpty {
                _ = drawText(episode.notes, font: smallFont, color: .darkGray)
            }

            drawLine()
        }

        context.endPDFPage()
        context.closePDF()

        try? pdfData.write(to: url, options: .atomic)
    }
}
