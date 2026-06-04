import AppKit
import SwiftUI   // chỉ dùng SwiftUI.Path để lấy squircle continuous đúng chuẩn Apple
import CoreText

/// Status bar icon mô phỏng input source indicator của macOS:
/// squircle (continuous corner, giống bo góc iPhone) + chữ semibold sắc nét ở giữa.
///
/// - Vietnamese (filled): nền đặc, chữ "khoét lỗ" (knockout) — giống "A" của ABC
/// - English (outline): vòng viền mảnh + chữ đặc — giống "VI" của Vietnamese IM
///
/// Vẽ trực tiếp bằng Core Graphics vào bitmap context ở đúng retina scale → chữ
/// sắc lẹm. (Render qua NSHostingView offscreen luôn rasterize ở 1x rồi phóng to
/// lên 2x nên bị mờ — xem docs/lessons.md.)
enum StatusBarIconRenderer {

    private static let height: CGFloat = 18
    private static let minWidth: CGFloat = 24    // khung bè ngang như native (tỉ lệ ~1.35)
    private static let cornerRadius: CGFloat = 6
    private static let fontSize: CGFloat = 12
    private static let fontWeight: NSFont.Weight = .semibold   // khớp độ đậm chữ của native
    private static let borderWidth: CGFloat = 1.0   // viền mảnh thanh nhã như native (English mode)
    private static let inset: CGFloat = 1        // chừa mép để biên ngoài không chạm cạnh
    private static let horizontalPadding: CGFloat = 12

    private static let font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)

    static func makeImage(text: String, filled: Bool) -> NSImage {
        let size = boxSize(for: text)
        let scale = NSScreen.main?.backingScaleFactor ?? 2

        let image = NSImage(size: size)
        if let rep = retinaBitmap(size: size, scale: scale) {
            drawIcon(text: text, filled: filled, size: size, into: rep)
            image.addRepresentation(rep)
        }
        image.isTemplate = true   // để macOS tự tint theo light/dark menu bar
        return image
    }

    /// Khung bè ngang cho một ký tự (như native input source), tự nới khi text dài hơn.
    private static func boxSize(for text: String) -> NSSize {
        let glyphWidth = measuredWidth(of: text)
        let width = max(ceil(glyphWidth) + horizontalPadding, minWidth)
        return NSSize(width: width, height: height)
    }

    private static func measuredWidth(of text: String) -> CGFloat {
        NSAttributedString(string: text, attributes: [.font: font]).size().width
    }

    private static func retinaBitmap(size: NSSize, scale: CGFloat) -> NSBitmapImageRep? {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * scale),
            pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
        )
        rep?.size = size   // size logic < pixel → context tự scale lên retina
        return rep
    }

    private static func drawIcon(text: String, filled: Bool, size: NSSize, into rep: NSBitmapImageRep) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        guard let nsContext = NSGraphicsContext(bitmapImageRep: rep) else { return }
        NSGraphicsContext.current = nsContext
        let context = nsContext.cgContext

        drawSquircle(filled: filled, size: size, in: context)
        drawCenteredGlyph(text, filled: filled, size: size, in: context)
    }

    private static func drawSquircle(filled: Bool, size: NSSize, in context: CGContext) {
        let box = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
        context.setFillColor(NSColor.black.cgColor)
        context.addPath(squirclePath(box, radius: cornerRadius))
        if filled {
            context.fillPath()
        } else {
            // Viền = squircle ngoài (trùng đúng biên ngoài của bản filled) trừ squircle trong,
            // tô even-odd → vòng viền đều, biên ngoài khít như filled (stroke thì lòi nửa nét
            // ra ngoài path nên góc bị mép bitmap cắt cụt → xấu).
            let innerBox = box.insetBy(dx: borderWidth, dy: borderWidth)
            context.addPath(squirclePath(innerBox, radius: cornerRadius - borderWidth))
            context.fillPath(using: .evenOdd)
        }
    }

    private static func squirclePath(_ rect: CGRect, radius: CGFloat) -> CGPath {
        SwiftUI.Path(roundedRect: rect, cornerRadius: radius, style: .continuous).cgPath
    }

    private static func drawCenteredGlyph(_ text: String, filled: Bool, size: NSSize, in context: CGContext) {
        let attributed = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: NSColor.black])
        let line = CTLineCreateWithAttributedString(attributed as CFAttributedString)

        // Căn giữa theo bounding box thật của nét chữ (optical centering)
        let glyphBounds = CTLineGetImageBounds(line, context)
        context.textPosition = CGPoint(
            x: (size.width - glyphBounds.width) / 2 - glyphBounds.origin.x,
            y: (size.height - glyphBounds.height) / 2 - glyphBounds.origin.y
        )

        if filled { context.setBlendMode(.destinationOut) }   // khoét chữ thành lỗ trong suốt
        CTLineDraw(line, context)
        context.setBlendMode(.normal)
    }
}
