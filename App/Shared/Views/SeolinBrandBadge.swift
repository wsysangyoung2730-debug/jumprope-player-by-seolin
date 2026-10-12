import SwiftUI

/// Keeps the supplied brand artwork legible in both light and dark appearances.
struct SeolinBrandBadge: View {
    var body: some View {
        Image("SeolinBrandBox")
            .resizable()
            .scaledToFit()
            .frame(width:58,height:56)
            .padding(3)
            .background(.white,in:RoundedRectangle(cornerRadius:8))
            .accessibilityLabel("서린태권도 SEOLIN TAEKWONDO")
            .help("JUMPROPE PLAYER by SEOLIN")
    }
}
