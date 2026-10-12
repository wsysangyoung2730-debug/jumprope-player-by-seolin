import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Compose the approved copy and existing artwork around unmodified native captures.
// This creates a sixth screenshot; the five feature screenshots remain unchanged.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("Marketing/AppStore")
let assets = root.appendingPathComponent("App/Resources/Assets.xcassets")
func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}
func load(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError(url.path) }
    return image
}
func canvas(_ width: Int, _ height: Int, alpha: Bool = false) -> CGContext {
    let c = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: (alpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast).rawValue)!
    c.translateBy(x: 0, y: CGFloat(height)); c.scaleBy(x: 1, y: -1)
    return c
}
func image(_ source: CGImage, _ rect: CGRect, _ c: CGContext) {
    c.saveGState(); c.translateBy(x: rect.minX, y: rect.maxY); c.scaleBy(x: 1, y: -1)
    c.interpolationQuality = .high
    c.draw(source, in: CGRect(origin: .zero, size: rect.size)); c.restoreGState()
}
func text(_ value: String, _ rect: CGRect, size: CGFloat, weight: NSFont.Weight = .regular,
          ink: NSColor = .white, lineSpacing: CGFloat = 10) {
    let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = lineSpacing
    let value = NSAttributedString(string: value, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: ink, .paragraphStyle: paragraph, .kern: -size * 0.035
    ])
    let fit = value.boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                                options: [.usesLineFragmentOrigin, .usesFontLeading])
    precondition(fit.height <= rect.height + 2, "Text exceeds its frame")
    value.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}
func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}
func write(_ context: CGContext, _ url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let bitmap = context.makeImage(),
          let out = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { fatalError("PNG creation failed") }
    CGImageDestinationAddImage(out, bitmap, nil); precondition(CGImageDestinationFinalize(out))
}
let icon = load(assets.appendingPathComponent("JumpRopeLogo.imageset/jumprope-player-logo.png"))
let brand = load(assets.appendingPathComponent("SeolinBrandBasic.imageset/seolin-logo-basic.png"))
// Use the supplied transparent wordmark with a white template tint, preserving its original shape.
let brandCanvas = canvas(brand.width, brand.height, alpha: true)
image(brand, CGRect(x: 0, y: 0, width: brand.width, height: brand.height), brandCanvas)
brandCanvas.setBlendMode(.sourceIn); brandCanvas.setFillColor(NSColor.white.cgColor)
brandCanvas.fill(CGRect(x: 0, y: 0, width: brand.width, height: brand.height))
let whiteBrand = brandCanvas.makeImage()!
let headline = "음악과 동작을 한눈에,\n줄넘기 연습에\n더 집중하세요."
let detail = "음악·영상과 순서표를 함께 보고,\n필요한 구간을 반복해서 연습하세요."
for (platform, prefix, width, height) in [("macOS", "mac", 2880, 1800), ("iPadOS", "ipad", 2064, 2752)] {
    let mac = platform == "macOS", w = CGFloat(width), h = CGFloat(height), c = canvas(width, height)
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: true)
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [color(0x1B2863).cgColor, color(0x284B87).cgColor] as CFArray, locations: [0, 1])!
    c.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: w, y: h), options: [])
    c.setFillColor(color(0x8EBBFF, 0.045).cgColor)
    c.fillEllipse(in: CGRect(x: w * 0.38, y: h * 0.48, width: w * 1.05, height: w * 1.05))
    if mac {
        text(headline, CGRect(x: 150, y: 236, width: 1030, height: 425), size: 88, weight: .bold, lineSpacing: 16)
        text(detail, CGRect(x: 156, y: 752, width: 1000, height: 155), size: 40, ink: color(0xD0DDF4), lineSpacing: 12)
        image(icon, CGRect(x: 140, y: 1085, width: 270, height: 270), c)
        text("JUMPROPE\nPLAYER", CGRect(x: 443, y: 1128, width: 680, height: 150), size: 55, weight: .semibold, lineSpacing: 5)
        text("by SEOLIN", CGRect(x: 448, y: 1302, width: 500, height: 55), size: 31, ink: color(0xD0DDF4))
    } else {
        text("음악과 동작을 한눈에,\n줄넘기 연습에 더 집중하세요.", CGRect(x: 135, y: 128, width: 1790, height: 300), size: 98, weight: .bold, lineSpacing: 13)
        text(detail, CGRect(x: 142, y: 454, width: 1775, height: 150), size: 46, ink: color(0xD0DDF4), lineSpacing: 10)
        image(icon, CGRect(x: 130, y: 653, width: 216, height: 216), c)
        text("JUMPROPE PLAYER", CGRect(x: 382, y: 698, width: 1395, height: 85), size: 61, weight: .semibold)
        text("by SEOLIN", CGRect(x: 387, y: 799, width: 620, height: 60), size: 35, ink: color(0xD0DDF4))
    }
    let shot = load(base.appendingPathComponent("Source/Captures/\(prefix)-1.png"))
    let shotWidth: CGFloat = mac ? 1550 : 1095
    let frame = CGRect(x: mac ? 1190 : (w - shotWidth) / 2, y: mac ? 420 : 1016,
                       width: shotWidth, height: shotWidth * CGFloat(shot.height) / CGFloat(shot.width))
    precondition(frame.maxX <= w - 100 && frame.maxY <= h - 150)
    c.saveGState(); c.setShadow(offset: CGSize(width: 0, height: 22), blur: 58, color: color(0x030B24, 0.48).cgColor)
    c.setFillColor(color(mac ? 0xFFFFFF : 0x111A2A).cgColor)
    c.addPath(rounded(frame.insetBy(dx: mac ? -2 : -15, dy: mac ? -2 : -15), mac ? 20 : 38))
    c.fillPath(); c.restoreGState()
    c.saveGState(); c.addPath(rounded(frame, mac ? 18 : 24)); c.clip(); image(shot, frame, c); c.restoreGState()
    let brandWidth: CGFloat = mac ? 240 : 205
    image(whiteBrand, CGRect(x: w - brandWidth - 136, y: h - brandWidth * CGFloat(brand.height) / CGFloat(brand.width) - 105,
                            width: brandWidth, height: brandWidth * CGFloat(brand.height) / CGFloat(brand.width)), c)
    NSGraphicsContext.restoreGraphicsState()
    let out = base.appendingPathComponent("ko-KR/\(platform)/06-intro.png")
    try write(c, out); print(out.path)
    // Include all six screenshots in the local overview without changing feature artwork.
    let overview = canvas(1800, mac ? 760 : 1580)
    overview.setFillColor(color(0xF0F4FC).cgColor)
    overview.fill(CGRect(x: 0, y: 0, width: 1800, height: mac ? 760 : 1580))
    for (i, file) in ["06-intro", "01-practice", "02-sync", "03-repeat", "04-scroll", "05-guide"].enumerated() {
        let item = load(base.appendingPathComponent("ko-KR/\(platform)/\(file).png"))
        let thumbWidth: CGFloat = 570, thumbHeight = thumbWidth * CGFloat(item.height) / CGFloat(item.width)
        image(item, CGRect(x: CGFloat(i % 3) * 590 + 20, y: CGFloat(i / 3) * (thumbHeight + 20) + 20,
                           width: thumbWidth, height: thumbHeight), overview)
    }
    try write(overview, base.appendingPathComponent("Overview/\(platform).png"))
}
