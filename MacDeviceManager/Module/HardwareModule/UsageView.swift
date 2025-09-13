import SwiftUI

enum UsageType: String {
    case cpu
    case memory
}

struct UsageView: View {
    let usageType: UsageType

    @State private var usageValue: Double = 0.0
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let cpuUsage = CPUUsage()
    private let memoryUsage = MemoryUsage()
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    var body: some View {
        VStack {
            CustomCircularGauge(value: usageValue, label: usageType == .cpu ? "UsageCpuTitle" : "UsageRamTitle", gaugeColor: .blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .onReceive(timer) { _ in
            switch usageType {
            case .cpu:
                usageValue = Double(cpuUsage.getCPUUsage())
            case .memory:
                usageValue = Double(memoryUsage.getMemoryPressurePercent())
            }
        }
    }
}

// 既存のCPU使用率取得関数（getCPUUsage()）をここに設置してください
#Preview {
    UsageView(usageType: .cpu)
}

// Previewでメモリ使用率表示
#Preview {
    UsageView(usageType: .memory)
}
