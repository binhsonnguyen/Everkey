import SwiftUI
import AppKit

/// Status bar icon mô phỏng input source indicator của macOS:
/// viền squircle (continuous curve, giống corner iPhone), text bold bên trong.
///
/// - Vietnamese (filled): nền đặc, chữ "khoét lỗ" (knockout) — giống "A" của ABC
/// - English (outline): chỉ viền + chữ — giống "VI" của Vietnamese IM
///
/// Render bằng NSImage drawing handler (retina-aware → sắc nét) thành template
/// image nên hệ thống tự tint trắng/đen theo menu bar.
enum StatusBarIconRenderer {

    static func makeImage(text: String, filled: Bool) -> NSImage {
        let height: CGFloat = 22
        let width = max(CGFloat(text.count) * 11 + 14, 28)
        let size = NSSize(width: width, height: height)

        let image = NSImage(size: size, flipped: false) { rect in
            guard let cg = NSGraphicsContext.current?.cgContext else { return false }

            let box = rect.insetBy(dx: 1.5, dy: 1.5)
            // Squircle path thật từ SwiftUI (continuous curve).
            let squircle = RoundedRectangle(cornerRadius: 7, style: .continuous)
                .path(in: box).cgPath

            let font = NSFont.systemFont(ofSize: 14, weight: .bold)
            let para = NSMutableParagraphStyle()
            para.alignment = .center
            let str = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: NSColor.black,
                .paragraphStyle: para,
            ])
            let strSize = str.size()
            let textPoint = CGPoint(
                x: (size.width - strSize.width) / 2,
                y: (size.height - strSize.height) / 2
            )

            if filled {
                cg.addPath(squircle)
                cg.setFillColor(NSColor.black.cgColor)
                cg.fillPath()
                // Khoét chữ thành lỗ trong suốt
                cg.setBlendMode(.destinationOut)
                str.draw(at: textPoint)
                cg.setBlendMode(.normal)
            } else {
                cg.addPath(squircle)
                cg.setStrokeColor(NSColor.black.cgColor)
                cg.setLineWidth(1.8)
                cg.strokePath()
                str.draw(at: textPoint)
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
