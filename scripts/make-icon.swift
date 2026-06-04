import AppKit

// Vẽ icon phong cách Google IME: bàn phím xám + "tag" cyan mang chữ V.
// Hệ toạ độ gốc dưới-trái. Mọi số theo canvas tham chiếu 1024, scale theo size.

func roundedRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

func drawIcon(size: CGFloat) -> Data {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let ctx = NSGraphicsContext.current!
    ctx.imageInterpolation = .high
    let s = size / 1024.0
    func S(_ v: CGFloat) -> CGFloat { v * s }

    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    // --- Bàn phím ---
    let bodyColor = NSColor(srgbRed: 0x5F/255, green: 0x63/255, blue: 0x68/255, alpha: 1)
    let keyColor  = NSColor(srgbRed: 0xD2/255, green: 0xD4/255, blue: 0xD6/255, alpha: 1)

    bodyColor.set()
    roundedRect(S(72), S(150), S(880), S(450), S(64)).fill()

    keyColor.set()
    let kr = S(18)
    // Hàng trên: 6 phím
    let innerX: CGFloat = 132, innerW: CGFloat = 760
    let keys = 6, gap: CGFloat = 24
    let keyW = (innerW - CGFloat(keys - 1) * gap) / CGFloat(keys)
    for i in 0..<keys {
        let x = innerX + CGFloat(i) * (keyW + gap)
        roundedRect(S(x), S(400), S(keyW), S(100), kr).fill()
    }
    // Hàng dưới: phím trái + space bar + phím phải
    roundedRect(S(132), S(250), S(118), S(100), kr).fill()
    roundedRect(S(280), S(250), S(464), S(100), kr).fill()
    roundedRect(S(774), S(250), S(118), S(100), kr).fill()

    // --- Tag cyan (ngũ giác, nhọn xuống) ---
    let teal = NSColor(srgbRed: 0x21/255, green: 0xC4/255, blue: 0xDC/255, alpha: 1)
    teal.set()
    let bodyTop: CGFloat = 912, bodyL: CGFloat = 255, bodyR: CGFloat = 545
    let r: CGFloat = 55, sideBottom: CGFloat = 650
    let tipX: CGFloat = 400, tipY: CGFloat = 500
    let p = NSBezierPath()
    p.move(to: NSPoint(x: S(bodyL), y: S(sideBottom)))
    p.line(to: NSPoint(x: S(bodyL), y: S(bodyTop - r)))
    p.appendArc(withCenter: NSPoint(x: S(bodyL + r), y: S(bodyTop - r)),
                radius: S(r), startAngle: 180, endAngle: 90, clockwise: true)
    p.line(to: NSPoint(x: S(bodyR - r), y: S(bodyTop)))
    p.appendArc(withCenter: NSPoint(x: S(bodyR - r), y: S(bodyTop - r)),
                radius: S(r), startAngle: 90, endAngle: 0, clockwise: true)
    p.line(to: NSPoint(x: S(bodyR), y: S(sideBottom)))
    p.line(to: NSPoint(x: S(tipX), y: S(tipY)))
    p.close()
    p.fill()

    // --- Chữ V trắng, căn giữa tag ---
    let fontSize = S(300)
    var font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
    if let rd = font.fontDescriptor.withDesign(.rounded) {
        font = NSFont(descriptor: rd, size: fontSize) ?? font
    }
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
    let str = NSAttributedString(string: "V", attributes: attrs)
    let tsize = str.size()
    let cx = S((bodyL + bodyR) / 2)
    let cy = S((sideBottom + bodyTop) / 2)
    str.draw(at: NSPoint(x: cx - tsize.width / 2, y: cy - tsize.height / 2))

    img.unlockFocus()

    let tiff = img.tiffRepresentation!
    let rep = NSBitmapImageRep(data: tiff)!
    return rep.representation(using: .png, properties: [:])!
}

// args: <outPath.png> <size>
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/icon-preview.png"
let size = CommandLine.arguments.count > 2 ? CGFloat(Double(CommandLine.arguments[2]) ?? 1024) : 1024
let png = drawIcon(size: size)
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) @\(Int(size))")
