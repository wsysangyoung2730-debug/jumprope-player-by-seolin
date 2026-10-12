import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Code-native artwork based on the sibling Blog Cover Maker / TCON layouts.
// Embed unretouched real native UI captures; never redraw controls or invent features.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("Marketing/AppStore")
struct Story { let file: String; let title: String; let detail: String }
let stories = [
    Story(file: "01-practice", title: "음악과 동작을, 한눈에.", detail: "내 음원과 순서표로 만드는 나만의 줄넘기 연습 공간"),
    Story(file: "02-sync", title: "동작이 바뀌는 순간, 싱크를 톡.", detail: "재생하며 시간을 기록하고, 0.1초 단위로 섬세하게 조정하세요."),
    Story(file: "03-repeat", title: "어려운 구간만, 한 번 더.", detail: "시작과 끝을 선택하면 원하는 동작을 반복할 수 있어요."),
    Story(file: "04-scroll", title: "리듬에 맞춰, 다음 동작으로.", detail: "자동 스크롤과 다음 동작 안내로 연습에 집중하세요."),
    Story(file: "05-guide", title: "첫 연습도, 차근차근 함께.", detail: "파일 추가부터 구간 반복까지, 6단계 사용 가이드")
]
func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255,
        blue: CGFloat(hex & 255)/255, alpha: alpha)
}
func load(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL,nil),
          let image = CGImageSourceCreateImageAtIndex(source,0,nil) else { fatalError(url.path) }
    return image
}
func image(_ source: CGImage, _ rect: CGRect, _ context: CGContext) {
    context.saveGState(); context.translateBy(x:rect.minX,y:rect.maxY); context.scaleBy(x:1,y:-1)
    context.interpolationQuality = .high
    context.draw(source,in:CGRect(origin:.zero,size:rect.size)); context.restoreGState()
}
func text(_ string: String, _ rect: CGRect, size: CGFloat, weight: NSFont.Weight = .regular, ink: NSColor) {
    let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 7
    let attributes: [NSAttributedString.Key:Any] = [.font:NSFont.systemFont(ofSize:size,weight:weight),
        .foregroundColor:ink,.paragraphStyle:paragraph,.kern: -size * 0.025]
    let attributed = NSAttributedString(string:string,attributes:attributes)
    let fit = attributed.boundingRect(with:CGSize(width:rect.width,height:CGFloat.greatestFiniteMagnitude), options:[.usesLineFragmentOrigin,.usesFontLeading])
    precondition(fit.height <= rect.height + 2, "Text overflow: \(string)")
    attributed.draw(with:rect,options:[.usesLineFragmentOrigin,.usesFontLeading])
}
func rounded(_ rect:CGRect,_ radius:CGFloat) -> CGPath { CGPath(roundedRect:rect,cornerWidth:radius,cornerHeight:radius,transform:nil) }
func write(_ context: CGContext, _ url: URL) throws {
    try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
    guard let output=context.makeImage(), let destination=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil) else { fatalError("write failed") }
    CGImageDestinationAddImage(destination,output,nil); precondition(CGImageDestinationFinalize(destination))
}
func canvas(_ width:Int,_ height:Int) -> CGContext {
    let context = CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,
        space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.translateBy(x:0,y:CGFloat(height)); context.scaleBy(x:1,y:-1)
    return context
}
for (platform, prefix, width, height) in [("macOS","mac",2880,1800),("iPadOS","ipad",2064,2752)] {
    for (index, story) in stories.enumerated() {
        let mac = platform == "macOS", dark = index == 0 || index == 2 || index == 3
        let w=CGFloat(width), h=CGFloat(height), context=canvas(width,height)
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current=NSGraphicsContext(cgContext:context,flipped:true)
        let colors = dark ? [color(0x121E50).cgColor,color(0x234D88).cgColor] : [color(0xF3F7FF).cgColor,color(0xDFEBFF).cgColor]
        let gradient=CGGradient(colorsSpace:CGColorSpace(name:CGColorSpace.sRGB),colors:colors as CFArray,locations:[0,1])!
        context.drawLinearGradient(gradient,start:.zero,end:CGPoint(x:w,y:h),options:[])
        context.setFillColor(color(0xFFFFFF,dark ? 0.03 : 0.28).cgColor)
        context.fillEllipse(in:CGRect(x:w*0.57,y:h*0.18,width:w*0.9,height:w*0.9))
        let ink=color(dark ? 0xFFFFFF : 0x172950), secondary=color(dark ? 0xC5D9F6 : 0x536882)
        text(mac ? story.title : story.title.replacingOccurrences(of: ", ", with: ",\n"),CGRect(x:120,y:mac ? 103 : 132,width:w-330,height:mac ? 128 : 295),size:mac ? 94 : 110,weight:.bold,ink:ink)
        text(story.detail,CGRect(x:126,y:mac ? 235 : 460,width:w-260,height:mac ? 64 : 128),size:39,ink:secondary)
        let shot=load(base.appendingPathComponent("Source/Captures/\(prefix)-\(index+1).png"))
        let top: CGFloat = mac ? 338 : 655
        let maxWidth=w-320, maxHeight=h-top-105
        let scale=min(maxWidth/CGFloat(shot.width),maxHeight/CGFloat(shot.height))
        let frame=CGRect(x:(w-CGFloat(shot.width)*scale)/2,y:top,width:CGFloat(shot.width)*scale,height:CGFloat(shot.height)*scale)
        precondition(frame.maxY < h-50)
        context.saveGState()
        context.setShadow(offset:CGSize(width:0,height:20),blur:52,color:color(0x030C26,dark ? 0.46 : 0.2).cgColor)
        context.setFillColor(color(mac ? 0xFFFFFF : 0x171B25).cgColor)
        context.addPath(rounded(frame.insetBy(dx:mac ? -2 : -13,dy:mac ? -2 : -13),mac ? 22 : 40)); context.fillPath(); context.restoreGState()
        context.saveGState(); context.addPath(rounded(frame,mac ? 20 : 28));context.clip();image(shot,frame,context);context.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        let output=base.appendingPathComponent("ko-KR/\(platform)/\(story.file).png")
        try write(context,output); print(output.path)
    }
    let overview=canvas(1800,platform == "macOS" ? 760 : 1580)
    overview.setFillColor(color(0xF0F4FC).cgColor);overview.fill(CGRect(x:0,y:0,width:1800,height:platform == "macOS" ? 760 : 1580))
    for (i,story) in stories.enumerated() {
        let shot=load(base.appendingPathComponent("ko-KR/\(platform)/\(story.file).png"))
        let row=i/3,col=i%3,width:CGFloat=570,height=570*CGFloat(shot.height)/CGFloat(shot.width)
        image(shot,CGRect(x:CGFloat(col)*590+20,y:CGFloat(row)*(height+20)+20,width:width,height:height),overview)
    }
    try write(overview,base.appendingPathComponent("Overview/\(platform).png"))
}
