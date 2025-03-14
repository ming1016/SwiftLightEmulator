import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ContentView: View {
    @State private var debugMode = false
    @State private var selectedExamples: Set<ExampleType> = Set(ExampleType.allCases)
    @State private var isRunning = false
    @State private var runResults: [ExampleType: String] = [:]

    var body: some View {
        VStack(spacing: 10) {
            Text("ARM64模拟器")
                .font(.title)
                .padding(.top)

            Divider()

            // 调试模式开关 - 修复废弃的 onChange API
            Toggle("调试模式", isOn: $debugMode)
                .padding(.horizontal)
                .onChange(of: debugMode) { _, newValue in
                    EmulatorDebugTools.shared.isDebugModeEnabled = newValue
                }

            // 示例选择
            VStack(alignment: .leading) {
                Text("选择要运行的示例:")
                    .font(.headline)
                    .padding(.bottom, 2)

                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(ExampleType.allCases, id: \.self) { example in
                            Toggle(example.title, isOn: Binding(
                                get: { selectedExamples.contains(example) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedExamples.insert(example)
                                    } else {
                                        selectedExamples.remove(example)
                                    }
                                }
                            ))
                            .padding(.vertical, 2)
                        }

                        HStack {
                            Button("全选") {
                                selectedExamples = Set(ExampleType.allCases)
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button("全不选") {
                                selectedExamples.removeAll()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
                .frame(height: 200)
                .background(backgroundStyle)
                .cornerRadius(8)
            }
            .padding(.horizontal)

            Divider()

            // 运行按钮
            Button(action: {
                Task {
                    await runSelectedExamples()
                }
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text(isRunning ? "运行中..." : "运行所选示例")
                }
                .frame(minWidth: 200)
                .padding()
            }
            .disabled(isRunning || selectedExamples.isEmpty)
            .buttonStyle(.borderedProminent)

            // 运行结果
            if !runResults.isEmpty {
                resultsSummaryView
            }

            Spacer()
        }
        .padding()
    }

    private var resultsSummaryView: some View {
        VStack(alignment: .leading) {
            Text("运行结果:")
                .font(.headline)
                .padding(.bottom, 5)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(runResults.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { example in
                        if let result = runResults[example] {
                            HStack(alignment: .top) {
                                Image(systemName: result.contains("✓") ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(result.contains("✓") ? .green : .red)

                                VStack(alignment: .leading) {
                                    Text(example.title)
                                        .font(.subheadline)
                                        .bold()
                                    Text(result)
                                        .font(.footnote)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }
            .frame(height: 150)
            .background(backgroundStyle)
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    // 跨平台背景样式
    private var backgroundStyle: some View {
        #if os(iOS)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }

    // 运行选中的示例
    private func runSelectedExamples() async {
        // 重置结果和状态
        isRunning = true
        runResults.removeAll()

        // 初始化示例管理器
        let manager = ExampleManager(debugMode: debugMode)

        // 逐个运行选中的示例
        for example in ExampleType.allCases where selectedExamples.contains(example) {
            // 运行示例并更新UI
            await MainActor.run {
                runResults[example] = "正在运行..."
            }

            let result = await manager.runExample(example)

            // 更新结果
            await MainActor.run {
                runResults[example] = result
            }
        }

        isRunning = false
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif















