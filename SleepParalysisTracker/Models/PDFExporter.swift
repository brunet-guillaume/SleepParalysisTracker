import AppKit
import PDFKit
import SwiftUI
import Charts

final class PDFExporter {
    @MainActor static func export(episodes: [Episode]) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = String(localized: "pdf.filename") + ".pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Force light appearance for PDF rendering
        let previousAppearance = NSApp.appearance
        NSApp.appearance = NSAppearance(named: .aqua)
        defer { NSApp.appearance = previousAppearance }

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

        func drawDotItems(_ label: String, items: [(name: String, color: NSColor)]) {
            let result = NSMutableAttributedString()

            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 9),
                .foregroundColor: NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
            ]
            result.append(NSAttributedString(string: label + " ", attributes: labelAttrs))

            for (index, item) in items.enumerated() {
                if index > 0 {
                    result.append(NSAttributedString(string: "  ", attributes: labelAttrs))
                }
                // Colored dot
                let dotAttrs: [NSAttributedString.Key: Any] = [
                    .font: smallFont,
                    .foregroundColor: item.color
                ]
                result.append(NSAttributedString(string: "●", attributes: dotAttrs))
                // Name in dark gray
                let nameAttrs: [NSAttributedString.Key: Any] = [
                    .font: smallFont,
                    .foregroundColor: NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
                ]
                result.append(NSAttributedString(string: " " + item.name, attributes: nameAttrs))
            }

            let framesetter = CTFramesetterCreateWithAttributedString(result)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSize(width: contentWidth, height: .greatestFiniteMagnitude), nil)
            let textHeight = ceil(suggestedSize.height)

            checkPageBreak(needed: textHeight + 4)

            let textRect = CGRect(x: margin, y: y - textHeight, width: contentWidth, height: textHeight)
            let path = CGPath(rect: textRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
            context.saveGState()
            context.textMatrix = .identity
            CTFrameDraw(frame, context)
            context.restoreGState()

            y -= textHeight + 4
        }

        func drawLabelValue(_ label: String, value: String) {
            let result = NSMutableAttributedString()
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 9),
                .foregroundColor: NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
            ]
            let normalAttrs: [NSAttributedString.Key: Any] = [
                .font: smallFont,
                .foregroundColor: NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
            ]
            result.append(NSAttributedString(string: label + " ", attributes: boldAttrs))
            result.append(NSAttributedString(string: value, attributes: normalAttrs))

            let framesetter = CTFramesetterCreateWithAttributedString(result)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSize(width: contentWidth, height: .greatestFiniteMagnitude), nil)
            let textHeight = ceil(suggestedSize.height)

            checkPageBreak(needed: textHeight + 4)

            let textRect = CGRect(x: margin, y: y - textHeight, width: contentWidth, height: textHeight)
            let path = CGPath(rect: textRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
            context.saveGState()
            context.textMatrix = .identity
            CTFrameDraw(frame, context)
            context.restoreGState()

            y -= textHeight + 4
        }

        func drawSwiftUIView<V: View>(_ view: V, width: CGFloat, height: CGFloat, xOffset: CGFloat = 0) {
            checkPageBreak(needed: height)

            let renderer = ImageRenderer(content:
                view
                    .environment(\.colorScheme, .light)
            )
            renderer.scale = 2.0

            if let nsImage = renderer.nsImage {
                let drawRect = NSRect(x: margin + xOffset, y: y - height, width: width, height: height)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
                nsImage.draw(in: drawRect)
                NSGraphicsContext.restoreGraphicsState()
            }

            y -= height
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
        y -= 8
        drawLine()

        // Charts
        let chartWidth = contentWidth
        let chartHeight: CGFloat = 140

        // Episodes per month
        let store = EpisodeStore()
        store.episodes = episodes
        let monthlyData = store.episodesByMonth().suffix(12)
        if !monthlyData.isEmpty {
            _ = drawText(String(localized: "stats.episodes_per_month"), font: headerFont)
            let chartView = Chart(monthlyData, id: \.month) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .frame(width: chartWidth, height: chartHeight)
            .padding(4)
            .background(.white)
            drawSwiftUIView(chartView, width: chartWidth, height: chartHeight + 8)
        }

        // Hallucination types
        let typeData = store.hallucinationTypeBreakdown()
        if !typeData.isEmpty {
            _ = drawText(String(localized: "stats.hallucination_types"), font: headerFont)
            let donutView = Chart(typeData, id: \.type) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(item.type.color)
                .cornerRadius(4)
            }
            .chartForegroundStyleScale(
                domain: typeData.map(\.type.label),
                range: typeData.map(\.type.color)
            )
            .chartLegend(spacing: 12)
            .frame(width: chartWidth, height: chartHeight)
            .padding(4)
            .background(.white)
            drawSwiftUIView(donutView, width: chartWidth, height: chartHeight + 8)
        }

        // Triggers
        let triggerData = store.triggerBreakdown()
        if !triggerData.isEmpty {
            _ = drawText(String(localized: "stats.triggers"), font: headerFont)
            let triggerView = Chart(triggerData, id: \.trigger) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(item.trigger.color)
                .cornerRadius(4)
            }
            .chartForegroundStyleScale(
                domain: triggerData.map(\.trigger.label),
                range: triggerData.map(\.trigger.color)
            )
            .chartLegend(spacing: 12)
            .frame(width: chartWidth, height: chartHeight)
            .padding(4)
            .background(.white)
            drawSwiftUIView(triggerView, width: chartWidth, height: chartHeight + 8)
        }

        // Stress over time
        let dailyStress = store.averageStressByDay()
        if dailyStress.count > 1 {
            _ = drawText(String(localized: "stats.stress_over_time"), font: headerFont)
            let stressView = Chart(dailyStress, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Stress", item.averageStress)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.orange.gradient)
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Stress", item.averageStress)
                )
                .foregroundStyle(.orange)
            }
            .chartYScale(domain: 1...10)
            .frame(width: chartWidth, height: chartHeight)
            .padding(4)
            .background(.white)
            drawSwiftUIView(stressView, width: chartWidth, height: chartHeight + 8)
        }

        drawLine()

        // Episodes
        for episode in sorted {
            checkPageBreak(needed: 80)

            // Date + stress
            let dateStr = dateFormatter.string(from: episode.date)
            _ = drawText(dateStr, font: headerFont)

            drawLabelValue(String(localized: "form.stress") + ":", value: "\(episode.stressLevel)/10")

            // Position
            if let pos = episode.sleepPosition {
                drawLabelValue(String(localized: "form.position") + ":", value: pos.label)
            }

            // Hallucinations with colored dots
            if episode.hasHallucination && !episode.hallucinationTypes.isEmpty {
                let items = episode.hallucinationTypes.sorted(by: { $0.label < $1.label }).map { type in
                    (name: type.label, color: type.nsColor)
                }
                drawDotItems(String(localized: "form.hallucination") + ":", items: items)
            }

            // Triggers with colored dots
            if !episode.triggers.isEmpty {
                let items = episode.triggers.sorted(by: { $0.label < $1.label }).map { trigger in
                    (name: trigger.label, color: trigger.nsColor)
                }
                drawDotItems(String(localized: "form.triggers") + ":", items: items)
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
