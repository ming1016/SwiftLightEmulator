//
//  OpcodeStatistics.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

/// 指令统计分析器 - 用于收集和分析指令使用情况
class OpcodeStatistics {
    // 单例模式
    static let shared = OpcodeStatistics()

    // 指令类别统计
    private var opcodeCounts: [UInt8: Int] = [:]
    private var instructionTypeMap: [UInt8: String] = [
        0x8A: "AND",
        0x8B: "ADD",
        0x91: "ADD immediate",
        0x9B: "MUL/MADD",
        0xCB: "SUB",
        0xD2: "MOV immediate",
        0xD5: "System (NOP等)",
        0xD6: "BR",
        0xEB: "SUBS",
        0x54: "B.cond",
        0x14: "B",
        0x17: "BL"
    ]

    private init() {}

    /// 重置统计数据
    func reset() {
        opcodeCounts = [:]
    }

    /// 记录指令使用情况
    func recordInstruction(_ instruction: UInt32) {
        let opcode = UInt8((instruction >> 24) & 0xFF)
        opcodeCounts[opcode, default: 0] += 1
    }

    /// 获取指令类型名称
    func getInstructionType(for opcode: UInt8) -> String {
        return instructionTypeMap[opcode] ?? "未知"
    }

    /// 获取统计报告
    func generateReport() -> String {
        var report = "指令使用统计报告:\n"

        // 按使用次数排序
        let sortedOpcodes = opcodeCounts.sorted { $0.value > $1.value }

        var totalInstructions = 0
        for (_, count) in opcodeCounts {
            totalInstructions += count
        }

        // 生成详细报告
        for (opcode, count) in sortedOpcodes {
            let percentage = Double(count) / Double(totalInstructions) * 100
            report += "- \(getInstructionType(for: opcode)) (0x\(String(format: "%02X", opcode))): \(count) 次 (\(String(format: "%.1f", percentage))%)\n"
        }

        return report
    }
}
