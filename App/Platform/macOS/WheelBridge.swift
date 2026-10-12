#if os(macOS)
import SwiftUI

struct WheelBridge: NSViewRepresentable {
    let enabled: Bool
    let step: (Int) -> Void
    func makeNSView(context:Context) -> WheelView { WheelView() }
    func updateNSView(_ view:WheelView,context:Context) { view.enabled = enabled; view.step = step }
    final class WheelView: NSView {
        var enabled = false
        var step: ((Int) -> Void)?
        var monitor: Any?
        var last = Date.distantPast
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching:.scrollWheel) { [weak self] event in
                guard let self, self.enabled, self.window === event.window, self.bounds.contains(self.convert(event.locationInWindow,from:nil)), abs(event.scrollingDeltaY) > 1 else { return event }
                if Date().timeIntervalSince(self.last) > 0.18 { self.last = Date(); self.step?(event.scrollingDeltaY < 0 ? 1 : -1) }
                return nil
            }
        }
        deinit { if let monitor { NSEvent.removeMonitor(monitor) } }
    }
}
#endif
