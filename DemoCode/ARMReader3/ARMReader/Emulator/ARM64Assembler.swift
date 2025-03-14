//
//  ARM64Assembler.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

/// ARM64汇编助手，用于生成正确的机器码
class ARM64Assembler {
    /// 条件码枚举
    enum ConditionCode: UInt32 {
        case eq = 0     // 相等 (Z=1)
        case ne = 1     // 不相等 (Z=0)
        case cs = 2     // 进位设置/高于或相等 (C=1)
        case cc = 3     // 进位清除/低于 (C=0)
        case mi = 4     // 负数 (N=1)
        case pl = 5     // 正数或零 (N=0)
        case vs = 6     // 溢出 (V=1)
        case vc = 7     // 无溢出 (V=0)
        case hi = 8     // 高于 (C=1 AND Z=0)
        case ls = 9     // 低于或相等 (C=0 OR Z=1)
        case ge = 10    // 大于等于 (N=V)
        case lt = 11    // 小于 (N!=V)
        case gt = 12    // 大于 (Z=0 AND N=V)
        case le = 13    // 小于等于 (Z=1 OR N!=V)
        case al = 14    // 总是 (默认)
        case nv = 15    // 从不 (罕用)
    }

    /// 生成MOV立即数指令
    static func movImmediate(rd: Int, imm16: UInt16) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        return 0xD2800000 | UInt32(rd) | (UInt32(imm16) << 5)
    }

    /// 生成ADD寄存器指令
    static func addRegister(rd: Int, rn: Int, rm: Int) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(rm >= 0 && rm <= 31, "寄存器索引必须在0-31之间")
        return 0x8B000000 | UInt32(rd) | (UInt32(rn) << 5) | (UInt32(rm) << 16)
    }

    /// 生成带立即数的ADD指令
    static func addRegister(rd: Int, rn: Int, rm: Int, immediate: UInt16 = 0) -> UInt32 {
        if (rm == 31 && immediate > 0 && immediate <= 4095) {
            // 生成ADD immediate (64-bit)指令: ADD Xd, Xn, #imm{, shift}
            // 指令格式: 1 0 0 1 0 0 0 1 shift(2) imm12(12) Rn(5) Rd(5)
            precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
            precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
            let imm12 = UInt32(immediate & 0xFFF)
            return 0x91000000 | (imm12 << 10) | (UInt32(rn) << 5) | UInt32(rd)
        } else {
            // 普通的寄存器到寄存器ADD
            return addRegister(rd: rd, rn: rn, rm: rm)
        }
    }

    /// 生成正确的ADD immediate指令
    static func addImmediate(rd: Int, rn: Int, immediate: UInt16) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(immediate <= 4095, "立即数必须≤4095")

        // 构造ADD immediate指令格式: 1 00 1 00 01 <shift=00> <imm12> <Rn> <Rd>
        let imm12 = UInt32(immediate & 0xFFF)
        let instruction = 0x91000000 | (imm12 << 10) | (UInt32(rn) << 5) | UInt32(rd)

        #if DEBUG
        // 验证生成的指令
        let extractedRd = instruction & 0x1F
        let extractedRn = (instruction >> 5) & 0x1F
        let extractedImm = (instruction >> 10) & 0xFFF
        print("ADD immediate指令验证:")
        print("  生成指令: 0x\(String(format: "%08X", instruction))")
        print("  解码: ADD X\(extractedRd), X\(extractedRn), #\(extractedImm)")
        #endif

        return instruction
    }

    /// 生成SUBS寄存器指令
    static func subsRegister(rd: Int, rn: Int, rm: Int) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(rm >= 0 && rm <= 31, "寄存器索引必须在0-31之间")
        return 0xEB000000 | UInt32(rd) | (UInt32(rn) << 5) | (UInt32(rm) << 16)
    }

    /// 生成条件分支指令
    static func conditionalBranch(condition: ConditionCode, offsetBytes: Int) -> UInt32 {
        // 条件分支偏移量是相对于当前指令的字偏移
        precondition(offsetBytes % 4 == 0, "偏移量必须是4的倍数")

        // 转换字节偏移为字偏移，范围是±1MB
        let offsetWords = offsetBytes / 4
        precondition(offsetWords >= -2_097_152 && offsetWords < 2_097_152, "偏移量超出范围")

        // 获取偏移量的低19位 (ARM64格式)
        // 注意：ARM64分支指令偏移量使用补码形式编码
        let imm19 = Int32(offsetWords) & 0x7FFFF

        // 组合指令
        let instruction = 0x54000000 | (UInt32(imm19) << 5) | condition.rawValue

        #if DEBUG
        // 验证偏移量编码正确性
        let encodedOffset = validateBranchOffset(instruction)
        print("生成条件分支: 条件码=\(condition.rawValue), 偏移字=\(offsetWords), 原始偏移量=\(offsetBytes), 编码后=\(encodedOffset)")
        #endif

        return instruction
    }

    /// 生成无条件分支指令
    static func unconditionalBranch(offsetBytes: Int, withLink: Bool = false) -> UInt32 {
        // 无条件分支偏移量也是相对于当前指令的字偏移
        precondition(offsetBytes % 4 == 0, "偏移量必须是4的倍数")

        // 转换字节偏移为字偏移，范围是±128MB
        let offsetWords = offsetBytes / 4
        precondition(offsetWords >= -67_108_864 && offsetWords < 67_108_864, "偏移量超出范围")

        // 提取偏移量的低26位
        let imm26 = UInt32(bitPattern: Int32(offsetWords)) & 0x3FFFFFF

        // 根据是否带链接选择基本操作码
        let baseOpcode: UInt32 = withLink ? 0x94000000 : 0x14000000

        // 组合指令
        return baseOpcode | imm26
    }

    /// 针对循环示例特别创建预定义的程序
    static func createLoopProgram() -> [UInt32] {
        var program: [UInt32] = []

        // 0x1000: 初始化寄存器
        program.append(movImmediate(rd: 0, imm16: 0))      // X0 = 0 (累加器)
        program.append(movImmediate(rd: 1, imm16: 1))      // X1 = 1 (计数器初值)
        program.append(movImmediate(rd: 2, imm16: 4))      // X2 = 4 (最大值)

        // 循环开始 (地址: 0x100C)
        let loopStart = 3  // 指令索引为3
        program.append(addRegister(rd: 0, rn: 0, rm: 1))   // X0 += X1 (累加当前计数值)

        // 修复：使用正确的ADD immediate指令，增加1而不是错误的值
        program.append(addImmediate(rd: 1, rn: 1, immediate: 1))  // X1 += 1 (正确递增计数器)

        program.append(subsRegister(rd: 31, rn: 1, rm: 2)) // CMP X1, X2 (比较计数器和最大值)

        // 使用LE条件码(13)，此时比较的是X1和X2
        let branchInstruction = conditionalBranch(condition: .le, offsetBytes: -12)
        program.append(branchInstruction)  // B.LE 循环开始

        // 程序结束标记
        program.append(0xD503201F)                         // NOP

        // 打印生成的程序和注释
        print("修正后的循环程序 (计算1+2+3+4=10):")
        for i in 0..<program.count {
            let addr = 0x1000 + i * 4
            var comment = ""
            switch i {
            case 0: comment = "MOV X0, #0  - 累加器初始化"
            case 1: comment = "MOV X1, #1  - 计数器初始值"
            case 2: comment = "MOV X2, #4  - 最大计数值"
            case 3: comment = "ADD X0, X0, X1  - 累加当前计数值"
            case 4: comment = "ADD X1, X1, #1  - 递增计数器(修正后)"
            case 5: comment = "SUBS XZR, X1, X2  - 比较计数器和最大值"
            case 6: comment = "B.LE -12  - 如果X1<=X2则跳回0x100C"
            case 7: comment = "NOP  - 程序结束"
            default: comment = ""
            }
            print("0x\(String(format: "%04X", addr)): 0x\(String(format: "%08X", program[i])) // \(comment)")

            // 添加特殊验证，确保计数器增加指令正确
            if i == 4 {
                let decoded = disassembleAddImmediate(program[i])
                print("   解码: \(decoded)")
            }
        }

        // 添加特殊断言，验证计数器增加指令正确
        assert((program[4] & 0xFFC003FF) == 0x91000021, "递增计数器指令格式错误")
        assert(((program[4] >> 10) & 0xFFF) == 1, "立即数应为1")

        // 执行流程说明
        print("\n预期执行流程:")
        print("1. 初始化: X0=0, X1=1, X2=4")
        print("2. 迭代1: X0=0+1=1, X1=1+1=2, 比较 2<=4? 是")
        print("3. 迭代2: X0=1+2=3, X1=2+1=3, 比较 3<=4? 是")
        print("4. 迭代3: X0=3+3=6, X1=3+1=4, 比较 4<=4? 是")
        print("5. 迭代4: X0=6+4=10, X1=4+1=5, 比较 5<=4? 否")
        print("6. 循环结束，最终结果: X0=10 (1+2+3+4)")

        return program
    }

    // 辅助函数：解析ADD立即数指令，用于调试
    private static func disassembleAddImmediate(_ instruction: UInt32) -> String {
        if (instruction & 0xFF000000) == 0x91000000 {
            let rd = Int(instruction & 0x1F)
            let rn = Int((instruction >> 5) & 0x1F)
            let imm12 = (instruction >> 10) & 0xFFF
            return "ADD X\(rd), X\(rn), #\(imm12)"
        } else {
            return "不是ADD immediate指令: 0x\(String(format: "%08X", instruction))"
        }
    }

    /// 验证分支指令的偏移量
    static func validateBranchOffset(_ instruction: UInt32) -> Int {
        // 检查是条件分支还是无条件分支
        let isConditional = (instruction & 0xFE000000) == 0x54000000

        if isConditional {
            // 条件分支，提取imm19
            let imm19 = Int32(bitPattern: ((instruction >> 5) & 0x7FFFF))

            // 符号扩展 (如果需要)
            let signExtended = (imm19 << 13) >> 13

            // 转换为字节偏移
            return Int(signExtended * 4)
        } else {
            // 无条件分支，提取imm26
            let imm26 = Int32(bitPattern: (instruction & 0x3FFFFFF))

            // 符号扩展
            let signExtended = (imm26 << 6) >> 6

            // 转换为字节偏移
            return Int(signExtended * 4)
        }
    }

    /// 分析ARM64指令格式
    static func analyzeInstruction(_ instruction: UInt32) -> String {
        var analysis = "指令分析: 0x\(String(format: "%08X", instruction))\n"

        // 提取主要操作码
        let opcode = (instruction >> 24) & 0xFF
        analysis += "主操作码: 0x\(String(format: "%02X", opcode))\n"

        // 分析不同指令类型
        if (instruction & 0xFE000000) == 0x54000000 {
            // 条件分支指令
            let condition = instruction & 0xF
            let imm19Raw = (instruction >> 5) & 0x7FFFF

            // 计算符号扩展后的值
            let imm19 = Int32(bitPattern: imm19Raw)
            let signExtended = (imm19 << 13) >> 13
            let offset = signExtended * 4

            // 添加更多条件码信息
            var conditionName = "未知"
            switch condition {
            case 0: conditionName = "EQ (等于)"
            case 1: conditionName = "NE (不等于)"
            case 2: conditionName = "CS/HS (进位设置/高于等于)"
            case 3: conditionName = "CC/LO (进位清除/低于)"
            case 4: conditionName = "MI (负数)"
            case 5: conditionName = "PL (正数或零)"
            case 6: conditionName = "VS (溢出)"
            case 7: conditionName = "VC (无溢出)"
            case 8: conditionName = "HI (高于)"
            case 9: conditionName = "LS (低于等于)"
            case 10: conditionName = "GE (大于等于)"
            case 11: conditionName = "LT (小于)"
            case 12: conditionName = "GT (大于)"
            case 13: conditionName = "LE (小于等于)"
            case 14: conditionName = "AL (总是)"
            case 15: conditionName = "NV (从不)"
            default: conditionName = "未知"
            }

            analysis += "类型: 条件分支 (B.cond)\n"
            analysis += "条件码: \(condition) - \(conditionName)\n"
            analysis += "原始偏移量位域(imm19): 0x\(String(format: "%05X", imm19Raw))\n"
            // 修复：添加缺少的右括号
            analysis += "符号扩展后: 0x\(String(format: "%08X", UInt32(bitPattern: signExtended)))\n"
            analysis += "最终字偏移: \(signExtended) (字), \(offset) (字节)\n"
            analysis += "目标地址计算: PC + \(offset) 字节\n"
            analysis += "二进制表示: \(String(instruction, radix: 2).padding(toLength: 32, withPad: "0", startingAt: 0))\n"

            // 分解二进制格式
            analysis += "二进制分解: "
            analysis += "\(String((instruction >> 24) & 0xFF, radix: 2).padding(toLength: 8, withPad: "0", startingAt: 0)) " // 高8位
            analysis += "\(String((instruction >> 16) & 0xFF, radix: 2).padding(toLength: 8, withPad: "0", startingAt: 0)) " // 次高8位
            analysis += "\(String((instruction >> 8) & 0xFF, radix: 2).padding(toLength: 8, withPad: "0", startingAt: 0)) "  // 次低8位
            analysis += "\(String(instruction & 0xFF, radix: 2).padding(toLength: 8, withPad: "0", startingAt: 0))\n"       // 最低8位

        } else if (instruction & 0xFC000000) == 0x14000000 || (instruction & 0xFC000000) == 0x94000000 {
            // 无条件分支指令
            let withLink = (instruction & 0xFC000000) == 0x94000000
            let imm26Raw = instruction & 0x3FFFFFF

            let imm26 = Int32(bitPattern: imm26Raw)
            let signExtended = (imm26 << 6) >> 6
            let offset = signExtended * 4

            analysis += "类型: \(withLink ? "带链接的" : "")无条件分支 (B\(withLink ? "L" : ""))\n"
            analysis += "偏移量原始值: 0x\(String(format: "%07X", imm26Raw))\n"
            analysis += "符号扩展后: 0x\(String(format: "%08X", UInt32(bitPattern: signExtended)))\n"
            analysis += "最终偏移量: \(offset) 字节\n"
        }

        return analysis
    }

    /// 创建一个精确的条件分支指令
    static func createExactBranchInstruction(condition: ConditionCode, offsetBytes: Int) -> UInt32 {
        // 打印偏移量位模式，帮助调试
        let offsetWords = offsetBytes / 4
        let imm19Value = Int32(offsetWords) & 0x7FFFF

        let instruction = 0x54000000 | (UInt32(imm19Value) << 5) | condition.rawValue

        print("创建精确分支指令:")
        print("  偏移字节: \(offsetBytes), 偏移字: \(offsetWords)")
        print("  imm19值: 0x\(String(format: "%05X", imm19Value))")
        print("  指令: 0x\(String(format: "%08X", instruction))")
        print("  验证偏移量: \(validateBranchOffset(instruction))")

        return instruction
    }
}
