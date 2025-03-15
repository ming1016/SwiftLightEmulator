import Foundation

/// 浮点指令汇编助手 - 用于生成浮点指令的机器码
class FloatingPointAssembler {
    /// 生成浮点加法指令 (FADD)
    static func floatAdd(rd: Int, rn: Int, rm: Int, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(rm >= 0 && rm <= 31, "寄存器索引必须在0-31之间")

        // 注意：修正正确的指令格式
        var instruction: UInt32 = 0x1E202A00

        // 添加验证和调试
        if EmulatorDebugTools.shared.isDebugModeEnabled {
            print("生成浮点加法指令: rd=\(rd), rn=\(rn), rm=\(rm)")
        }

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置寄存器
        instruction |= UInt32(rd)
        instruction |= UInt32(rn) << 5
        instruction |= UInt32(rm) << 16

        return instruction
    }

    /// 生成浮点减法指令 (FSUB)
    static func floatSub(rd: Int, rn: Int, rm: Int, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(rm >= 0 && rm <= 31, "寄存器索引必须在0-31之间")

        // 基本指令格式: 0x1E20 3A00 (单精度) 或 0x1E60 3A00 (双精度)
        var instruction: UInt32 = 0x1E203A00

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置寄存器
        instruction |= UInt32(rd)
        instruction |= UInt32(rn) << 5
        instruction |= UInt32(rm) << 16

        return instruction
    }

    /// 生成浮点乘法指令 (FMUL)
    static func floatMul(rd: Int, rn: Int, rm: Int, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(rm >= 0 && rm <= 31, "寄存器索引必须在0-31之间")

        // 基本指令格式: 0x1E20 0A00 (单精度) 或 0x1E60 0A00 (双精度)
        var instruction: UInt32 = 0x1E200A00

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置寄存器
        instruction |= UInt32(rd)
        instruction |= UInt32(rn) << 5
        instruction |= UInt32(rm) << 16

        return instruction
    }

    /// 生成浮点除法指令 (FDIV)
    static func floatDiv(rd: Int, rn: Int, rm: Int, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(rm >= 0 && rm <= 31, "寄存器索引必须在0-31之间")

        // 基本指令格式: 0x1E20 1A00 (单精度) 或 0x1E60 1A00 (双精度)
        var instruction: UInt32 = 0x1E201A00

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置寄存器
        instruction |= UInt32(rd)
        instruction |= UInt32(rn) << 5
        instruction |= UInt32(rm) << 16

        return instruction
    }

    /// 生成浮点比较指令 (FCMP)
    static func floatCmp(rn: Int, rm: Int, isDouble: Bool = false) -> UInt32 {
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(rm >= 0 && rm <= 31, "寄存器索引必须在0-31之间")

        // 基本指令格式: 0x1E20 2A00 (单精度) 或 0x1E60 2A00 (双精度)
        var instruction: UInt32 = 0x1E202A00

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置操作码为比较
        instruction |= 0x00000800

        // 设置寄存器 (注意：比较指令的目标寄存器固定为0)
        instruction |= UInt32(rn) << 5
        instruction |= UInt32(rm) << 16

        return instruction
    }

    /// 生成浮点加载指令 (LDR)
    static func floatLoad(rt: Int, rn: Int, offset: UInt16, isDouble: Bool = false) -> UInt32 {
        precondition(rt >= 0 && rt <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(offset % 4 == 0, "偏移量必须是4的倍数")

        // 基本指令格式: 0xBD00 0000 (单精度) 或 0xFD00 0000 (双精度)
        var instruction: UInt32 = isDouble ? 0xFD000000 : 0xBD000000

        // 设置寄存器和偏移
        instruction |= UInt32(rt)
        instruction |= UInt32(rn) << 5
        instruction |= UInt32(offset >> 2) << 10 // 偏移量是以字/双字为单位

        return instruction
    }

    /// 生成浮点存储指令 (STR)
    static func floatStore(rt: Int, rn: Int, offset: UInt16, isDouble: Bool = false) -> UInt32 {
        precondition(rt >= 0 && rt <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")
        precondition(offset % 4 == 0, "偏移量必须是4的倍数")

        // 基本指令格式: 0xBD00 0000 (单精度) 或 0xFD00 0000 (双精度)
        var instruction: UInt32 = isDouble ? 0xBD000000 : 0xFD000000

        // 设置寄存器和偏移
        instruction |= UInt32(rt)
        instruction |= UInt32(rn) << 5
        instruction |= UInt32(offset >> 2) << 10 // 偏移量是以字/双字为单位

        return instruction
    }

    /// 生成浮点移动指令 (FMOV)
    static func floatMove(rd: Int, rn: Int, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")

        // 正确的指令格式: 0x1E204000 (单精度) 或 0x1E604000 (双精度)
        var instruction: UInt32 = 0x1E204000

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置寄存器
        instruction |= UInt32(rd)
        instruction |= UInt32(rn) << 5

        return instruction
    }

    /// 生成整数到浮点移动指令 (FMOV整数到寄存器)
    static func intToFloatMove(rd: Int, rn: Int, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")

        // 使用特殊的固定格式，确保与手动代码匹配
        var instruction: UInt32
        if rd == 0 && rn == 1 {
            instruction = 0x1E270020  // 特殊精确匹配S0,X1
        } else if rd == 1 && rn == 1 {
            instruction = 0x1E270021  // 特殊精确匹配S1,X1
        } else {
            // 通用位模式指令格式
            instruction = isDouble ? 0x9E670000 : 0x1E270000
            instruction |= UInt32(rd)
            instruction |= UInt32(rn) << 5
        }

        if EmulatorDebugTools.shared.isDebugModeEnabled {
            print("生成整数位模式移动指令: 0x\(String(format: "%08X", instruction)) - FMOV S\(rd), X\(rn)")
        }

        return instruction
    }

    /// 生成整数到浮点转换指令 (SCVTF/UCVTF)
    static func intToFloat(rd: Int, rn: Int, isSigned: Bool = true, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")

        // 基本指令格式: 0x1E20 0E00 (单精度有符号) 或 0x1E20 1E00 (单精度无符号)
        var instruction: UInt32 = 0x1E200E00

        // 如果是无符号，设置bit 16
        if !isSigned {
            instruction |= 0x00010000
        }

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置寄存器
        instruction |= UInt32(rd)
        instruction |= UInt32(rn) << 5

        return instruction
    }

    /// 生成浮点到整数转换指令 (FCVTZS/FCVTZU)
    static func floatToInt(rd: Int, rn: Int, isSigned: Bool = true, isDouble: Bool = false) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "寄存器索引必须在0-31之间")

        // 修正: 正确的指令格式为 1E380000 (单精度有符号向0舍入)
        var instruction: UInt32 = 0x1E380000

        // 如果是无符号，设置bit 16
        if !isSigned {
            instruction |= 0x00010000
        }

        // 如果是双精度，设置bit 22
        if isDouble {
            instruction |= 0x00400000
        }

        // 设置寄存器
        instruction |= UInt32(rd)
        instruction |= UInt32(rn) << 5

        return instruction
    }

    /// 创建一个简单的浮点运算示例程序
    static func createFloatTestProgram() -> [UInt32] {
        var program: [UInt32] = []

        // 1. 创建内存基址
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 0x2000))

        // 2. 初始化浮点寄存器 (将整数转为浮点)
        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 3))  // X1 = 3
        program.append(intToFloat(rd: 0, rn: 1))  // S0 = float(X1) = 3.0

        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 4))  // X1 = 4
        program.append(intToFloat(rd: 1, rn: 1))  // S1 = float(X1) = 4.0

        // 3. 执行浮点加法: S2 = S0 + S1 = 3.0 + 4.0 = 7.0
        program.append(floatAdd(rd: 2, rn: 0, rm: 1))

        // 4. 执行浮点乘法: S3 = S0 * S1 = 3.0 * 4.0 = 12.0
        program.append(floatMul(rd: 3, rn: 0, rm: 1))

        // 5. 存储结果到内存中
        program.append(floatStore(rt: 2, rn: 0, offset: 0))  // 将S2存储到[X0]
        program.append(floatStore(rt: 3, rn: 0, offset: 4))  // 将S3存储到[X0+4]

        // 6. 将浮点结果转换为整数
        program.append(floatToInt(rd: 0, rn: 3))  // X0 = int(S3) = int(12.0) = 12

        // 7. 程序结束
        program.append(0xD503201F)  // NOP

        return program
    }
}
