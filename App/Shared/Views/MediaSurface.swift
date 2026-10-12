import SwiftUI
import AVKit
#if os(macOS)
struct MediaSurface: NSViewRepresentable {
    let player: AVPlayer
    func makeNSView(context:Context) -> AVPlayerView { let view = AVPlayerView(); view.controlsStyle = .none; view.videoGravity = .resizeAspect; return view }
    func updateNSView(_ view:AVPlayerView,context:Context) { view.player = player }
}
#else
struct MediaSurface: UIViewRepresentable {
    let player: AVPlayer
    final class Surface: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
    func makeUIView(context:Context) -> Surface { let view = Surface(); view.playerLayer.videoGravity = .resizeAspect; return view }
    func updateUIView(_ view:Surface,context:Context) { view.playerLayer.player = player }
}
#endif
