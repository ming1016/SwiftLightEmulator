//
//  EmulatorError.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//



// 添加帮助方法来验证指令格式
extension InstructionDecoder {
    // 辅助方法：检查MUL指令的格式
    func isMulInstruction(_ instruction: UInt32) -> Bool {
        // 检查不同的MUL指令格式
        // ARM64 MUL指令格式较为复杂，这里简化处理
        // 完整实现应该参考ARM架构参考手册

        let opcode = (instruction >> 24) & 0xFF

        // 检查基本操作码
        if opcode != 0x9B {
            return false
        }

        // MUL有多种格式，根据不同的位模式进行检查
        // 1. 标准的寄存器MUL - MADD/MSUB形式
        let op31 = (instruction >> 31) & 0x1
        let op21 = (instruction >> 21) & 0xF

        // 这是一个简化检查，真实ARM64有更复杂的匹配逻辑
        return (op31 == 0) && ((op21 == 0xB) || (op21 == 0xA))
    }
}

// 添加扩展方法来辅助ARM64指令解码
extension UInt32 {
    // 从指令中提取特定位域
    func bitField(_ msb: Int, _ lsb: Int) -> UInt32 {
        precondition(msb >= lsb && msb < 32 && lsb >= 0, "位域范围无效")
        let mask = (1 << (msb - lsb + 1)) - 1
        return (self >> UInt32(lsb)) & UInt32(mask)
    }

    // 检查MUL指令格式
    var isARM64MUL: Bool {
        // 检查基本格式是否符合MADD格式
        let op31_21 = self.bitField(31, 21)
        if op31_21 != 0x4D8 { return false }  // 0x4D8 = 10011011000二进制

        // 检查Ra是否为31 (ZR寄存器)
        let ra = self.bitField(15, 10)
        return ra == 31  // Ra=31表示MUL指令
    }
}

// 打印函数 - 用于调试二进制指令结构
func printInstructionDetails(_ instruction: UInt32) {
    print("指令: 0x\(String(format: "%08X", instruction))")
    print("二进制: \(String(instruction, radix: 2).padding(toLength: 32, withPad: "0", startingAt: 0))")
    print("op[31:24]: 0x\(String(format: "%02X", (instruction >> 24) & 0xFF))")
    print("op[31:21]: 0x\(String(format: "%03X", (instruction >> 21) & 0x7FF))")
    print("Rm[20:16]: \((instruction >> 16) & 0x1F)")
    print("Ra[15:10]: \((instruction >> 10) & 0x1F)")
    print("Rn[9:5]: \((instruction >> 5) & 0x1F)")
    print("Rd[4:0]: \(instruction & 0x1F)")
}
