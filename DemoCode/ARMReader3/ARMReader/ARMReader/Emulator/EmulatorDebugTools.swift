//
//  EmulatorDebugTools.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

/// 模拟器调试工具 - 用于提供调试输出和程序验证功能
class EmulatorDebugTools {
    // 单例模式
    static let shared = EmulatorDebugTools()

    // 是否启用详细调试输出
    var isDebugModeEnabled = false

    private init() {}

    /// 打印程序指令
    func printProgram(_ program: [UInt32], baseAddress: UInt64, withDescription: Bool = false) {
        guard isDebugModeEnabled else { return }

        print("生成的程序代码:")
        for (i, instruction) in program.enumerated() {
            let address = baseAddress + UInt64(i * 4)
            print("0x\(String(format: "%04X", address)): 0x\(String(format: "%08X", instruction))")
        }

        if withDescription {
            print("\n循环程序分析:")
            print("1. 累加器X0初始化为0")
            print("2. 循环计数器X1初始化为1")
            print("3. 最大值X2设为4")
            print("4. 循环开始: 将当前计数X1加到累加器X0")
            print("5. 增加计数器X1")
            print("6. 比较X1与X2")
            print("7. 如果X1<=X2，则继续循环")
            print("8. 循环结束后，X0应包含1+2+3+4=10")
        }
    }

    /// 验证循环程序指令
    func validateLoopProgram(_ program: [UInt32]) {
        guard isDebugModeEnabled else { return }

        print("验证循环程序指令:")

        // 1. 验证累加指令
        print("1. 累加指令(0x100C): \(String(format: "%08X", program[3]))")
        print("   解码: ADD X0, X0, X1")

        // 2. 验证递增计数器指令
        print("2. 递增计数器指令(0x1010): \(String(format: "%08X", program[4]))")
        let rd = program[4] & 0x1F
        let rn = (program[4] >> 5) & 0x1F
        let imm = (program[4] >> 10) & 0xFFF
        print("   解码: ADD X\(rd), X\(rn), #\(imm)")

        if rd == 1 && rn == 1 && imm == 1 {
            print("   ✓ 正确的递增指令，每次加1")
        } else if rd == 1 && rn == 1 {
            print("   ✗ 递增指令数值错误，应为#1，实际为#\(imm)")
        } else {
            print("   ✗ 递增指令格式错误")
        }

        // 3. 验证比较指令
        print("3. 比较指令(0x1014): \(String(format: "%08X", program[5]))")
        print("   解码: SUBS XZR, X1, X2")

        // 4. 验证分支指令
        print("4. 分支指令(0x1018): \(String(format: "%08X", program[6]))")
        print("   偏移量: \(ARM64Assembler.validateBranchOffset(program[6])) 字节")
    }

    /// 创建SUB指令
    func createSubInstruction(rd: Int, rn: Int, rm: Int) -> UInt32 {
        // SUB Xd, Xn, Xm 指令格式: 1 1 0 0 1 0 1 1 (shift) Rm Rn Rd
        return 0xCB000000 | UInt32(rd) | (UInt32(rn) << 5) | (UInt32(rm) << 16)
    }

    /// 创建AND指令
    func createAndInstruction(rd: Int, rn: Int, rm: Int) -> UInt32 {
        // AND Xd, Xn, Xm 指令格式: 1 0 0 0 1 0 1 0 (shift) Rm Rn Rd
        return 0x8A000000 | UInt32(rd) | (UInt32(rn) << 5) | (UInt32(rm) << 16)
    }

    /// 创建MUL指令
    func createMulInstruction(rd: Int, rn: Int, rm: Int) -> UInt32 {
        // MUL Xd, Xn, Xm 实际上是 MADD Xd, Xn, Xm, XZR 指令
        // 指令格式: 1 0 0 1 1 0 1 1 0 0 0 Rm 0 1 1 1 1 1 Rn Rd
        return 0x9B000000 | UInt32(rd) | (UInt32(rn) << 5) | (UInt32(31) << 10) | (UInt32(rm) << 16)
    }

    /// 验证分支指令偏移量
    func validateBranchOffset(_ instruction: UInt32, expectedOffset: Int) -> Bool {
        guard isDebugModeEnabled else { return true }

        let offset = ARM64Assembler.validateBranchOffset(instruction)
        print("分支指令验证: 0x\(String(format: "%08X", instruction)), 偏移量=\(offset)")
        print("期望偏移量: \(expectedOffset), 实际偏移量: \(offset), \(offset == expectedOffset ? "✓" : "✗")")

        return offset == expectedOffset
    }

    /// 打印执行结果摘要
    func printExecutionSummary(_ emulator: LightEmulator, description: String) {
        let result = emulator.getRegister(0)
        print("\(description): \(result)")

        // 打印性能数据
        if isDebugModeEnabled {
            print("寄存器状态: X0=\(emulator.getRegister(0)), X1=\(emulator.getRegister(1)), X2=\(emulator.getRegister(2))")
        }
    }
}
