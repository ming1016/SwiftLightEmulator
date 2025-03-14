//
//  PerformanceMetrics.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

/// 性能指标跟踪器 - 用于监控模拟器执行效率
class PerformanceMetrics {
    // 单例模式
    static let shared = PerformanceMetrics()

    // 性能计数器
    private var instructionsExecuted: UInt64 = 0
    private var branchesTaken: UInt64 = 0
    private var loopsExecuted: UInt64 = 0
    private var executionTime: TimeInterval = 0

    // 开始时间点
    private var startTime: Date?

    private init() {}

    /// 开始计时
    func startMeasuring() {
        reset()
        startTime = Date()
    }

    /// 停止计时
    func stopMeasuring() {
        if let start = startTime {
            executionTime = Date().timeIntervalSince(start)
            startTime = nil
        }
    }

    /// 重置所有指标
    func reset() {
        instructionsExecuted = 0
        branchesTaken = 0
        loopsExecuted = 0
        executionTime = 0
        startTime = nil
    }

    /// 递增已执行指令计数
    func incrementInstructions(by count: UInt64 = 1) {
        instructionsExecuted += count
    }

    /// 递增分支跳转计数
    func incrementBranches(by count: UInt64 = 1) {
        branchesTaken += count
    }

    /// 递增循环计数
    func incrementLoops(by count: UInt64 = 1) {
        loopsExecuted += count
    }

    /// 获取当前统计数据的字符串表示
    func getStatisticsString() -> String {
        var result = "模拟器执行统计:\n"
        result += "- 执行指令总数: \(instructionsExecuted)\n"
        result += "- 分支跳转次数: \(branchesTaken)\n"
        result += "- 循环执行次数: \(loopsExecuted)\n"

        let ips: Double = executionTime > 0 ? Double(instructionsExecuted) / executionTime : 0
        result += "- 总执行时间: \(String(format: "%.6f", executionTime)) 秒\n"
        result += "- 执行速度: \(String(format: "%.2f", ips)) 指令/秒\n"

        return result
    }

    /// 获取性能摘要
    var summary: String {
        "指令数: \(instructionsExecuted), 耗时: \(String(format: "%.3f", executionTime))秒"
    }

    /// 当前状态的简短描述
    var statusDescription: String {
        if startTime != nil {
            return "测量中..."
        } else if executionTime > 0 {
            return "完成 (\(summary))"
        } else {
            return "就绪"
        }
    }
}
