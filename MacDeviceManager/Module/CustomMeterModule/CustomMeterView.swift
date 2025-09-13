import SwiftUI

struct CustomCircularGauge: View {
    var value: Double   // 0〜100比例尺
    var label: LocalizedStringKey
    var gaugeColor: Color
    
    private let lineWidth: CGFloat = 16
    private let size: CGFloat = 180
    private let totalDegrees: Double = 270  // ゲージ角度幅
    private let startAngle: Double = 135    // 左下スタート(135度)
    
    // 危険ゾーン・警告ゾーン開始（%）
    private let dangerThreshold: Double = 80
    private let warningThreshold: Double = 60
    
    var body: some View {
        VStack {
            Text(label)
                .font(.headline)
            
            ZStack {
                // 背景の扇形（270度, 薄い）
                Circle()
                    .trim(from: 0, to: CGFloat(totalDegrees / 360))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .foregroundColor(gaugeColor.opacity(0.15))
                    .rotationEffect(Angle(degrees: startAngle))
                    .frame(width: size, height: size)
                
                // 警告ゾーン（しきい値60~80%部分だけ黄色）
                Circle()
                    .trim(
                        from: CGFloat((totalDegrees * warningThreshold / 100) / 360),
                        to: CGFloat((totalDegrees * dangerThreshold / 100) / 360)
                    )
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .foregroundColor(Color.yellow.opacity(0.5))
                    .rotationEffect(Angle(degrees: startAngle))
                    .frame(width: size, height: size)
                
                // 危険ゾーン（しきい値80~100%部分だけ赤色）
                Circle()
                    .trim(
                        from: CGFloat((totalDegrees * dangerThreshold / 100) / 360),
                        to: CGFloat(totalDegrees / 360)
                    )
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .foregroundColor(Color.red.opacity(0.5))
                    .rotationEffect(Angle(degrees: startAngle))
                    .frame(width: size, height: size)
                
                // 針 (Needle)
                Needle()
                    .fill(value >= dangerThreshold ? Color.red : (value >= warningThreshold ? Color.yellow : gaugeColor))
                    .frame(width: lineWidth / 2, height: size / 2)
                    .offset(y: -size / 4)
                    .rotationEffect(Angle(degrees: -startAngle))
                    .rotationEffect(Angle(degrees: totalDegrees * min(max(value, 0), 100) / 100))
                    .animation(.easeOut(duration: 0.5), value: value)
                    .frame(width: size, height: size)
                
                // 中央の値表示
                Text("\(Int(value))%")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(value >= dangerThreshold ? .red : (value >= warningThreshold ? .yellow : gaugeColor))
                    .offset(y: size * 0.4)
            }
            .padding(.top, 10)
        }
        .padding()
        .scaleEffect(0.7)
    }
}

struct Needle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let bottomY = rect.maxY
        path.move(to: CGPoint(x: centerX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: bottomY))
        path.addLine(to: CGPoint(x: rect.minX, y: bottomY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack {
        CustomCircularGauge(value: 0, label: "CPU利用率", gaugeColor: .blue)
        CustomCircularGauge(value: 45, label: "CPU利用率", gaugeColor: .blue)
        CustomCircularGauge(value: 65, label: "メモリ利用率", gaugeColor: .green)
        CustomCircularGauge(value: 85, label: "GPU利用率", gaugeColor: .purple)
        CustomCircularGauge(value: 100, label: "GPU利用率", gaugeColor: .purple)
    }
}
