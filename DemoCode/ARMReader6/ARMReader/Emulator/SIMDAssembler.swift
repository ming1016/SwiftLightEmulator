//
//  SIMDAssembler.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/16.
//

import Foundation

/// SIMD指令汇编助手 - 用于生成SIMD指令的机器码
class SIMDAssembler {
    /// 生成向量加法指令 (VADD)
    static func vectorAdd(vd: Int, vn: Int, vm: Int, elementSize: SIMDExecutor.ElementSize) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vm >= 0 && vm <= 31, "向量寄存器索引必须在0-31之间")

        // 使用与 SIMDExecutor 兼容的指令格式
        var instruction: UInt32 = 0x4E200400

        // 设置寄存器索引
        instruction |= UInt32(vd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(vm) << 16

        // 设置元素大小
        let sizeEncoding: UInt32
        switch elementSize {
        case .byte:
            sizeEncoding = 0b00
        case .halfword:
            sizeEncoding = 0b01
        case .word:
            sizeEncoding = 0b10
        case .doubleword:
            sizeEncoding = 0b11
        }
        instruction |= sizeEncoding << 22

        // 打印调试信息并验证指令格式
        if EmulatorDebugTools.shared.isDebugModeEnabled {
            print("生成向量加法指令: V\(vd) = V\(vn) + V\(vm) (\(elementSize))")
            print("  机器码: 0x\(String(format:"%08X", instruction))")

            // 验证关键位字段
            print("  指令格式验证:")
            print("  - 操作码(31-24): 0x\(String(format:"%02X", (instruction >> 24) & 0xFF))")
            print("  - 大小位(23-22): \(sizeEncoding)")
            print("  - Rm(20-16): \(vm)")
            print("  - Rn(9-5): \(vn)")
            print("  - Rd(4-0): \(vd)")
        }

        return instruction
    }

    /// 生成向量减法指令 (VSUB)
    static func vectorSub(vd: Int, vn: Int, vm: Int, elementSize: SIMDExecutor.ElementSize) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vm >= 0 && vm <= 31, "向量寄存器索引必须在0-31之间")

        // 使用与 SIMDExecutor 兼容的指令格式
        var instruction: UInt32 = 0x4E200C00

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(vm) << 16

        // 设置元素大小
        let sizeEncoding: UInt32
        switch elementSize {
        case .byte:
            sizeEncoding = 0b00
        case .halfword:
            sizeEncoding = 0b01
        case .word:
            sizeEncoding = 0b10
        case .doubleword:
            sizeEncoding = 0b11
        }
        instruction |= sizeEncoding << 22

        return instruction
    }

    /// 生成向量乘法指令 (VMUL)
    static func vectorMul(vd: Int, vn: Int, vm: Int, elementSize: SIMDExecutor.ElementSize) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vm >= 0 && vm <= 31, "向量寄存器索引必须在0-31之间")
        precondition(elementSize != .doubleword, "不支持64位元素的向量乘法")

        // 使用与 SIMDExecutor 兼容的指令格式
        var instruction: UInt32 = 0x4E209C00

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(vm) << 16

        // 设置元素大小
        let sizeEncoding: UInt32
        switch elementSize {
        case .byte:
            sizeEncoding = 0b00
        case .halfword:
            sizeEncoding = 0b01
        case .word:
            sizeEncoding = 0b10
        default:
            fatalError("不支持64位元素的向量乘法")
        }
        instruction |= sizeEncoding << 22

        return instruction
    }

    /// 生成向量按位与指令 (VAND)
    static func vectorAnd(vd: Int, vn: Int, vm: Int) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vm >= 0 && vm <= 31, "向量寄存器索引必须在0-31之间")

        // 基本指令格式 (采用逻辑指令格式，不受元素大小控制)
        var instruction: UInt32 = 0x4E201C00

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(vm) << 16

        return instruction
    }

    /// 生成向量按位或指令 (VORR)
    static func vectorOr(vd: Int, vn: Int, vm: Int) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vm >= 0 && vm <= 31, "向量寄存器索引必须在0-31之间")

        // 基本指令格式
        var instruction: UInt32 = 0x4EA01C00

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(vm) << 16

        return instruction
    }

    /// 生成向量按位异或指令 (VEOR)
    static func vectorXor(vd: Int, vn: Int, vm: Int) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vm >= 0 && vm <= 31, "向量寄存器索引必须在0-31之间")

        // 基本指令格式
        var instruction: UInt32 = 0x6E201C00

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(vm) << 16

        return instruction
    }

    /// 生成向量元素复制指令 (VDUP)
    static func vectorDup(vd: Int, vn: Int, index: Int, elementSize: SIMDExecutor.ElementSize) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")

        // 检查索引范围
        switch elementSize {
        case .byte:
            precondition(index >= 0 && index < 16, "字节元素索引必须在0-15之间")
        case .halfword:
            precondition(index >= 0 && index < 8, "半字元素索引必须在0-7之间")
        case .word:
            precondition(index >= 0 && index < 4, "字元素索引必须在0-3之间")
        case .doubleword:
            precondition(index >= 0 && index < 2, "双字元素索引必须在0-1之间")
        }

        // 基本指令格式
        var instruction: UInt32 = 0x4E080C00

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(vn) << 5

        // 设置元素大小和索引
        let sizeEncoding: UInt32
        var indexEncoding: UInt32

        switch elementSize {
        case .byte:
            sizeEncoding = 0b00
            indexEncoding = UInt32(index & 0xF)
        case .halfword:
            sizeEncoding = 0b01
            indexEncoding = UInt32(index & 0x7)
        case .word:
            sizeEncoding = 0b10
            indexEncoding = UInt32(index & 0x3)
        case .doubleword:
            sizeEncoding = 0b11
            indexEncoding = UInt32(index & 0x1)
        }

        instruction |= sizeEncoding << 22
        instruction |= indexEncoding << 16

        return instruction
    }

    /// 生成向量加载指令 (LD1)
    static func vectorLoad(vd: Int, rn: Int, immediate: UInt8 = 0, postIncrement: Bool = false) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "基址寄存器索引必须在0-31之间")

        // 基本指令格式 (LD1 {Vt.16B}, [Xn]) 或带后增量 (LD1 {Vt.16B}, [Xn], #16)
        var instruction: UInt32 = 0x4C407400

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(rn) << 5

        // 设置后增量模式
        if postIncrement {
            instruction |= 0x1 << 23
        }

        // 设置立即数偏移(仅用于变址寻址)
        if immediate > 0 {
            instruction |= (UInt32(immediate) & 0xFF) << 12
        }

        return instruction
    }

    /// 生成向量存储指令 (ST1)
    static func vectorStore(vd: Int, rn: Int, immediate: UInt8 = 0, postIncrement: Bool = false) -> UInt32 {
        precondition(vd >= 0 && vd <= 31, "向量寄存器索引必须在0-31之间")
        precondition(rn >= 0 && rn <= 31, "基址寄存器索引必须在0-31之间")

        // 基本指令格式 (ST1 {Vt.16B}, [Xn]) 或带后增量 (ST1 {Vt.16B}, [Xn], #16)
        var instruction: UInt32 = 0x4C007400

        // 设置寄存器
        instruction |= UInt32(vd)
        instruction |= UInt32(rn) << 5

        // 设置后增量模式
        if postIncrement {
            instruction |= 0x1 << 23
        }

        // 设置立即数偏移(仅用于变址寻址)
        if immediate > 0 {
            instruction |= (UInt32(immediate) & 0xFF) << 12
        }

        return instruction
    }

    /// 生成向量到标量的移动指令
    static func vectorToScalar(rd: Int, vn: Int, index: Int) -> UInt32 {
        precondition(rd >= 0 && rd <= 31, "寄存器索引必须在0-31之间")
        precondition(vn >= 0 && vn <= 31, "向量寄存器索引必须在0-31之间")
        precondition(index >= 0 && index < 16, "字节索引必须在0-15之间")

        // 自定义格式的SIMD到标量指令
        var instruction: UInt32 = 0x0D000000
        instruction |= UInt32(rd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(index) << 10

        return instruction
    }

    /// 生成简单的SIMD测试程序
    static func createSIMDTestProgram() -> [UInt32] {
        var program: [UInt32] = []

        // 1. 设置数据缓冲区地址
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 0x2000))

        // 2. 加载两个向量
        program.append(vectorLoad(vd: 0, rn: 0))
        program.append(ARM64Assembler.addImmediate(rd: 0, rn: 0, immediate: 16))
        program.append(vectorLoad(vd: 1, rn: 0))

        // 3. 执行向量加法
        program.append(vectorAdd(vd: 2, vn: 0, vm: 1, elementSize: .byte))

        // 4. 将结果移回标量寄存器
        program.append(vectorToScalar(rd: 0, vn: 2, index: 0))

        // 5. 程序结束
        program.append(0xD503201F) // NOP

        return program
    }

    /// 解码验证SIMD指令
    static func decodeSIMDInstruction(_ instruction: UInt32) -> String {
        let majorOpcode = (instruction >> 24) & 0xFF
        var description = "SIMD指令: 0x\(String(format: "%08X", instruction)), 主操作码: 0x\(String(format: "%02X", majorOpcode))\n"

        if majorOpcode == 0x4C {
            // 加载/存储指令
            let isLoad = ((instruction >> 22) & 0x1) == 1
            let rd = Int(instruction & 0x1F)
            let rn = Int((instruction >> 5) & 0x1F)

            description += isLoad ?
                "LD1 {V\(rd).16B}, [X\(rn)]" :
                "ST1 {V\(rd).16B}, [X\(rn)]"

            // 检查后增模式
            if ((instruction >> 23) & 0x1) == 1 {
                description += ", #16"
            }
        } else if majorOpcode == 0x4E {
            // 数据处理指令
            let rd = Int(instruction & 0x1F)
            let rn = Int((instruction >> 5) & 0x1F)
            let rm = Int((instruction >> 16) & 0x1F)

            // 判断指令类型
            let opField = (instruction >> 10) & 0x1F
            let opField2 = (instruction >> 21) & 0x1
            let size = (instruction >> 22) & 0x3
            let sizeStr: String

            switch size {
            case 0: sizeStr = "8位"
            case 1: sizeStr = "16位"
            case 2: sizeStr = "32位"
            case 3: sizeStr = "64位"
            default: sizeStr = "未知"
            }

            if (instruction & 0x0F20FC00) == 0x0E20FC00 {
                description += "向量加法 (VADD.\(sizeStr)): V\(rd) = V\(rn) + V\(rm)"
            } else if (instruction & 0x0F20FC00) == 0x0E20FC00 {
                description += "向量减法 (VSUB.\(sizeStr)): V\(rd) = V\(rn) - V\(rm)"
            } else if (instruction & 0x9F203C00) == 0x0E209C00 {
                description += "向量乘法 (VMUL.\(sizeStr)): V\(rd) = V\(rn) * V\(rm)"
            } else if (instruction & 0x9F200C00) == 0x0E200000 {
                if (instruction & 0x00000C00) == 0x00000000 {
                    description += "向量按位与 (VAND): V\(rd) = V\(rn) & V\(rm)"
                } else if (instruction & 0x00000C00) == 0x00000400 {
                    description += "向量按位或 (VORR): V\(rd) = V\(rn) | V\(rm)"
                } else {
                    description += "向量按位异或 (VEOR): V\(rd) = V\(rn) ^ V\(rm)"
                }
            }
        } else if majorOpcode == 0x0D {
            // 自定义SIMD到标量指令
            let rd = Int(instruction & 0x1F)
            let vn = Int((instruction >> 5) & 0x1F)
            let index = Int((instruction >> 10) & 0xF)
            description += "向量到标量移动: X\(rd) = V\(vn).B[\(index)]"
        }

        return description
    }
}
