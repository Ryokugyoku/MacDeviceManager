//
//  DashboardView.swift
//  MacDeviceManager
//
//  Created by Maeda Mitsuhiro on 2025/09/13.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 上部の概要を示すカード
                HStack(spacing: 20) {
                    DashboardCard(title: "売上", value: "$120K", systemImageName: "chart.bar.fill", color: .blue)
                    DashboardCard(title: "訪問者数", value: "8,456", systemImageName: "person.2.fill", color: .green)
                }
                .padding(.horizontal)

                // 中央に大きめのメインカード
                DashboardCard(title: "収益グラフ", value: "今月の推移", systemImageName: "waveform.path.ecg", color: .orange)
                    .frame(height: 200)
                    .padding(.horizontal)

                // 下部に複数の小さいカード群
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    DashboardCard(title: "新規登録", value: "230", systemImageName: "person.crop.circle.badge.plus", color: .purple)
                    DashboardCard(title: "エラー数", value: "5", systemImageName: "exclamationmark.triangle.fill", color: .red)
                    DashboardCard(title: "サポートチケット", value: "12", systemImageName: "envelope.fill", color: .teal)
                    DashboardCard(title: "稼働時間", value: "99.9%", systemImageName: "clock.fill", color: .gray)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("ダッシュボード")
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let systemImageName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImageName)
                    .font(.largeTitle)
                    .foregroundColor(color)
                Spacer()
            }
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

#Preview {
    DashboardView()
}
