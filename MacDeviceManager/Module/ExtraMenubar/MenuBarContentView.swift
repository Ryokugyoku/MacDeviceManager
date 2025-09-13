
import SwiftUI

struct MenuBarContentView: View {
    var body: some View {
        VStack(){
            UsageView(usageType: .cpu)
            UsageView(usageType: .memory)
        }.padding(20)
        
    }
}

#Preview("Japanese / Light") {
    MenuBarContentView()
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .preferredColorScheme(.light)
}

#Preview("Japanese / Dark") {
    MenuBarContentView()
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .preferredColorScheme(.dark)
}

#Preview("English / Light") {
    MenuBarContentView()
        .environment(\.locale, Locale(identifier: "en_US"))
        .preferredColorScheme(.light)
}

#Preview("English / Dark") {
    MenuBarContentView()
        .environment(\.locale, Locale(identifier: "en_US"))
        .preferredColorScheme(.dark)
}

