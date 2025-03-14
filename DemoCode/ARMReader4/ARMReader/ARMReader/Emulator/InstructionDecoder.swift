//
//  InstructionDecoder.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//
import Foundation

// 指令解码器 - 负责解析和执行各种ARM指令
class InstructionDecoder {
    func decode(_ instruction: UInt32, cpu: ARM64CPU, bus: SystemBus) throws {
        let op31_24 = (instruction >> 24) & 0xFF

        // 判断是否处于调试模式
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        // 为调试添加指令信息输出
        if debugMode {
            print("解码指令: 0x\(String(format: "%08X", instruction)) 操作码: 0x\(String(format: "%02X", op31_24))")
        }

        switch op31_24 {
        case 0x91: // ADD immediate 指令
            executeADDImmediate(instruction, cpu: cpu)

        case 0x8B: // ADD 寄存器 指令
            executeADD(instruction, cpu: cpu)

        case 0xEB: // SUBS 指令（带标志位设置的减法）
            executeSUBS(instruction, cpu: cpu)

        case 0xCB: // SUB 指令
            executeSUB(instruction, cpu: cpu)

        case 0xD1: // SUB immediate 指令
            executeSUBImmediate(instruction, cpu: cpu)

        case 0x9B: // MUL/MADD 指令族
            // ARM64中的MUL实际上是MADD的特殊形式 (Ra=31)
            let op31_21 = (instruction >> 21) & 0x7FF // 检查高11位操作码

            // 检查是否为MADD/MSUB系列(高11位为10011011000)
            if op31_21 == 0x4D8 {  // 0x4D8 = 10011011000二进制
                // 提取Ra寄存器索引 (bit[15:10])
                let ra = (instruction >> 10) & 0x1F

                // 如果Ra=31 (ZR寄存器)，则这是MUL指令
                if ra == 31 {
                    executeMUL(instruction, cpu: cpu)
                } else {
                    // 这是MADD指令，目前不支持
                    throw EmulatorError.unsupportedInstructionFormat(
                        format: "0x\(String(format: "%08X", instruction))",
                        opcode: UInt8(op31_24),
                        details: "MADD指令暂不支持，Ra=\(ra)"
                    )
                }
            } else {
                // 不是标准的MADD/MUL指令格式
                throw EmulatorError.unsupportedInstructionFormat(
                    format: "0x\(String(format: "%08X", instruction))",
                    opcode: UInt8(op31_24),
                    details: "不是有效的MADD/MUL指令格式，op[31:21]=0x\(String(format: "%X", op31_21))"
                )
            }

        case 0x8A: // AND 指令
            executeAND(instruction, cpu: cpu)

        case 0xAA: // ORR 指令 (寄存器)
            executeORR(instruction, cpu: cpu)

        case 0x92, 0x93: // ORR immediate 指令
            executeORRImmediate(instruction, cpu: cpu)

        case 0xCA: // EOR 指令 (寄存器)
            executeEOR(instruction, cpu: cpu)

        case 0xD2, 0xD3: // MOV immediate 指令
            executeMOV(instruction, cpu: cpu)

        case 0xAB: // LSL/LSR/ASR 指令 (寄存器移位)
            executeShift(instruction, cpu: cpu)

        case 0xD4: // LSL/LSR/ASR immediate 指令
            executeShiftImmediate(instruction, cpu: cpu)

        case 0x9A: // SDIV/UDIV 指令
            executeDivision(instruction, cpu: cpu)

        case 0xD5: // 系统指令
            // 目前仅支持NOP
            if instruction != 0xD503201F {
                throw EmulatorError.unsupportedInstruction(UInt8(op31_24))
            }

        case 0x54: // B.cond (条件分支)
            executeConditionalBranch(instruction, cpu: cpu)

        case 0x14, 0x17: // B, BL (无条件分支/带链接)
            executeUnconditionalBranch(instruction, cpu: cpu)

        case 0xD6: // BR (寄存器间接跳转)
            executeRegisterBranch(instruction, cpu: cpu)

        default:
            #if DEBUG
            if instruction == 0 {
                print("遇到空指令(全0)，可能是跳转到未初始化内存区域")
                throw EmulatorError.unsupportedInstructionFormat(
                    format: "0x00000000",
                    opcode: 0,
                    details: "空指令(全0)，可能是跳转地址计算错误导致"
                )
            }
            #endif
            throw EmulatorError.unsupportedInstruction(UInt8(op31_24))
        }
    }

    // 添加新方法：专门处理ADD immediate指令
    private func executeADDImmediate(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let imm12 = (instruction >> 10) & 0xFFF
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("执行 ADD X\(rd), X\(rn), #\(imm12)")
            let before = cpu.getRegister(UInt32(rn))
            // 获取源寄存器值
            let srcValue = cpu.getRegister(UInt32(rn))
            // 添加立即数（确保是UInt64以避免溢出）
            let result = srcValue + UInt64(imm12)
            // 设置目标寄存器
            cpu.setRegister(UInt32(rd), value: result)
            print("ADD immediate: X\(rd) = X\(rn)(\(before)) + \(imm12) = \(result)")
        } else {
            // 非调试模式下的精简版本
            let srcValue = cpu.getRegister(UInt32(rn))
            let result = srcValue + UInt64(imm12)
            cpu.setRegister(UInt32(rd), value: result)
        }
    }

    // 修正现有的ADD寄存器指令执行方法，确保它只处理寄存器格式
    private func executeADD(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("执行 ADD X\(rd), X\(rn), X\(rm)")
            print("操作数: X\(rn)=\(operand1), X\(rm)=\(operand2)")
        }

        let result = operand1 + operand2

        cpu.setRegister(UInt32(rd), value: result)
        cpu.updateFlags(result: result, operand1: operand1, operand2: operand2, isAddition: true)

        if debugMode {
            print("ADD 结果: X\(rd) = \(operand1) + \(operand2) = \(result)")
        }
    }

    private func executeSUB(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))
        let result = operand1 - operand2

        cpu.setRegister(UInt32(rd), value: result)
        cpu.updateFlags(result: result, operand1: operand1, operand2: operand2, isAddition: false)
    }

    private func executeSUBImmediate(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let imm12 = (instruction >> 10) & 0xFFF
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("执行 SUB X\(rd), X\(rn), #\(imm12)")
        }

        // 获取源寄存器值
        let srcValue = (rn == 31) ? UInt64(0) : cpu.getRegister(UInt32(rn)) // 处理ZR寄存器

        // 减去立即数（确保是UInt64以避免溢出）
        let result = srcValue &- UInt64(imm12) // 使用&-操作符可以防止溢出错误

        // 设置目标寄存器
        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("SUB immediate: X\(rd) = X\(rn)(\(srcValue)) - \(imm12) = \(result)")
        }
    }

    private func executeMUL(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)           // 目标寄存器 [4:0]
        let rn = Int((instruction >> 5) & 0x1F)    // 第一个源寄存器 [9:5]
        let rm = Int((instruction >> 16) & 0x1F)   // 第二个源寄存器 [20:16]
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("执行 MUL X\(rd), X\(rn), X\(rm)")
            print("操作数: X\(rn)=\(cpu.getRegister(UInt32(rn))), X\(rm)=\(cpu.getRegister(UInt32(rm)))")
        }

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))
        let result = operand1 * operand2

        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("结果: X\(rd)=\(result)")
        }
    }

    private func executeAND(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)

        let result = cpu.getRegister(UInt32(rn)) & cpu.getRegister(UInt32(rm))
        cpu.setRegister(UInt32(rd), value: result)
    }

    private func executeORR(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))

        if debugMode {
            print("执行 ORR X\(rd), X\(rn), X\(rm)")
            print("操作数: X\(rn)=\(operand1), X\(rm)=\(operand2)")
        }

        let result = operand1 | operand2

        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("ORR 结果: X\(rd) = \(operand1) | \(operand2) = \(result)")
        }
    }

    private func executeORRImmediate(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)

        // 提取和解码立即数字段
        // 这里需要特殊处理，因为ARM64中立即数可能需要重新排列
        // 简化版本:
        let imm = (instruction >> 10) & 0xFFF
        let shiftAmount = ((instruction >> 22) & 0x3) * 16
        let immValue = UInt64(imm) << shiftAmount
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("执行 ORR immediate X\(rd), X\(rn), #\(immValue)")
        }

        let operand1 = cpu.getRegister(UInt32(rn))
        let result = operand1 | immValue

        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("ORR immediate 结果: X\(rd) = \(operand1) | \(immValue) = \(result)")
        }
    }

    private func executeEOR(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))

        if debugMode {
            print("执行 EOR X\(rd), X\(rn), X\(rm)")
            print("操作数: X\(rn)=\(operand1), X\(rm)=\(operand2)")
        }

        let result = operand1 ^ operand2

        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("EOR 结果: X\(rd) = \(operand1) ^ \(operand2) = \(result)")
        }
    }

    private func executeMOV(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let imm16 = (instruction >> 5) & 0xFFFF
        cpu.setRegister(UInt32(rd), value: UInt64(imm16))
    }

    private func executeShift(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let opcode = (instruction >> 10) & 0x3F
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        let value = cpu.getRegister(UInt32(rn))
        let shift = Int(cpu.getRegister(UInt32(rm)) & 0x3F) // 只取低6位作为移位量
        var result: UInt64 = 0

        // 根据操作码确定移位类型
        switch opcode {
        case 0x00: // LSL (逻辑左移)
            result = value << shift
            if debugMode { print("执行 LSL X\(rd), X\(rn), X\(rm) (左移\(shift)位)") }
        case 0x01: // LSR (逻辑右移)
            result = value >> shift
            if debugMode { print("执行 LSR X\(rd), X\(rn), X\(rm) (右移\(shift)位)") }
        case 0x02: // ASR (算术右移)
            result = UInt64(bitPattern: Int64(bitPattern: value) >> shift)
            if debugMode { print("执行 ASR X\(rd), X\(rn), X\(rm) (算术右移\(shift)位)") }
        default:
            if debugMode { print("不支持的移位类型: \(opcode)") }
            return
        }

        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("移位结果: X\(rd) = \(result)")
        }
    }

    private func executeShiftImmediate(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let shift = Int((instruction >> 10) & 0x3F) // 6位移位量
        let opcode = (instruction >> 22) & 0x3
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        let value = cpu.getRegister(UInt32(rn))
        var result: UInt64 = 0

        // 根据操作码确定移位类型
        switch opcode {
        case 0x0: // LSL (逻辑左移)
            result = value << shift
            if debugMode { print("执行 LSL X\(rd), X\(rn), #\(shift)") }
        case 0x1: // LSR (逻辑右移)
            result = value >> shift
            if debugMode { print("执行 LSR X\(rd), X\(rn), #\(shift)") }
        case 0x2: // ASR (算术右移)
            result = UInt64(bitPattern: Int64(bitPattern: value) >> shift)
            if debugMode { print("执行 ASR X\(rd), X\(rn), #\(shift)") }
        default:
            if debugMode { print("不支持的移位类型: \(opcode)") }
            return
        }

        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("立即数移位结果: X\(rd) = \(result)")
        }
    }

    private func executeDivision(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let opcode = (instruction >> 10) & 0xFF
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        // 获取操作数，处理ZR寄存器
        let dividend = (rn == 31) ? UInt64(0) : cpu.getRegister(UInt32(rn))
        let divisor = (rm == 31) ? UInt64(0) : cpu.getRegister(UInt32(rm))
        var result: UInt64 = 0

        // 检查除以零的情况
        if divisor == 0 {
            // ARM64标准中，除以零的结果为0
            result = 0
            if debugMode { print("警告: 除以零操作，结果设为0") }
        } else {
            if opcode & 0x1 == 0 { // UDIV (无符号除法)
                result = dividend / divisor
                if debugMode { print("执行 UDIV X\(rd), X\(rn), X\(rm)") }
            } else { // SDIV (有符号除法)
                let signedDividend = Int64(bitPattern: dividend)
                let signedDivisor = Int64(bitPattern: divisor)
                // 安全处理有符号除法，防止INT_MIN / -1 导致溢出
                if signedDividend == Int64.min && signedDivisor == -1 {
                    result = UInt64(bitPattern: Int64.min) // 保持为最小值
                    if debugMode { print("特殊情况: INT_MIN / -1 = INT_MIN (避免溢出)") }
                } else {
                    result = UInt64(bitPattern: signedDividend / signedDivisor)
                }
                if debugMode { print("执行 SDIV X\(rd), X\(rn), X\(rm)") }
            }
        }

        cpu.setRegister(UInt32(rd), value: result)

        if debugMode {
            print("除法结果: X\(rd) = \(result)")
        }
    }

    // 执行条件分支指令
    private func executeConditionalBranch(_ instruction: UInt32, cpu: ARM64CPU) {
        // 提取条件码 (bits [3:0])
        let condition = instruction & 0xF

        // 从ARM64Assembler获取偏移量，确保正确处理
        let offset = Int32(ARM64Assembler.validateBranchOffset(instruction))
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            // 以十进制和十六进制显示偏移量，便于调试
            print("条件分支: 条件码=\(condition), 偏移量=\(offset) (0x\(String(format: "%X", offset)))")
        }

        // 如果条件满足，则执行分支
        if evaluateCondition(Int(condition), cpu: cpu) {
            // 计算目标地址，注意PC相对寻址
            let currentPC = cpu.pc

            // 使用Int64避免溢出
            let targetPC = UInt64(Int64(bitPattern: currentPC) + Int64(offset))

            if debugMode {
                print("分支计算详情:")
                print("  当前PC: 0x\(String(format: "%016X", currentPC))")
                print("  偏移量: \(offset) (0x\(String(format: "%X", offset)))")
                print("  目标PC: 0x\(String(format: "%016X", targetPC))")

                // 验证目标地址的指令指向
                if targetPC >= 0x1000 && targetPC < 0x2000 {
                    // 假设程序加载在0x1000-0x2000范围内
                    print("  目标指令索引: \((targetPC - 0x1000) / 4)")
                }
            }

            // 安全检查目标地址
            if targetPC < 0x1000 || targetPC % 4 != 0 {
                if debugMode {
                    print("警告: 分支目标地址无效 0x\(String(format: "%016X", targetPC))")
                }
            }

            if debugMode {
                print("条件成立，从地址 0x\(String(format: "%016X", cpu.pc)) 分支到地址: 0x\(String(format: "%016X", targetPC))")
            }

            cpu.pc = targetPC
        } else {
            if debugMode {
                print("条件不成立，继续执行下一条指令")
            }
        }
    }

    // 执行无条件分支指令
    private func executeUnconditionalBranch(_ instruction: UInt32, cpu: ARM64CPU) {
        // 检查是否是带链接的分支 (BL)
        let isLink = ((instruction >> 24) & 0xFF) == 0x17

        // 提取偏移量 (bits [25:0])
        var imm26 = instruction & 0x3FFFFFF

        // 符号扩展 (如果最高位为1)
        if (imm26 & 0x2000000) != 0 {
            imm26 |= 0xFC000000
        }

        // 偏移量需要左移2位（字对齐）
        let offset = Int64(Int32(bitPattern: UInt32(imm26 << 2)))
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("无条件分支: 类型=\(isLink ? "BL" : "B"), 偏移量=\(offset)")
        }

        // 如果是带链接的分支，保存返回地址
        if isLink {
            // X30 是链接寄存器 (LR)，保存下一条指令的地址
            cpu.setRegister(30, value: cpu.pc + 4)
        }

        // 计算目标地址，注意PC已经指向当前指令
        let targetPC = UInt64(Int64(cpu.pc) + offset)

        if debugMode {
            print("从地址 0x\(String(format: "%016X", cpu.pc)) 分支到地址: 0x\(String(format: "%016X", targetPC))")
        }

        cpu.pc = targetPC
    }

    // 执行寄存器间接跳转指令
    private func executeRegisterBranch(_ instruction: UInt32, cpu: ARM64CPU) {
        // BR指令的操作码格式检查 (1101011 0000 11111 000000 Rn 00000)
        let opc = (instruction >> 21) & 0x7FF

        if opc != 0x358 { // 0x358 = 1101011000
            // 不是BR指令
            let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

            if debugMode {
                print("不支持的寄存器分支类型: 0x\(String(format: "%X", opc))")
            }
            return
        }

        // 提取寄存器索引 (bits [9:5])
        let rn = (instruction >> 5) & 0x1F

        // 从寄存器获取目标地址
        let targetAddr = cpu.getRegister(UInt32(rn))
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("寄存器间接跳转: BR X\(rn), 目标地址=0x\(String(format: "%016X", targetAddr))")
        }

        // 更新PC
        cpu.pc = targetAddr - 4  // 减4是因为执行完后会自动加4
    }

    // 条件评估逻辑
    private func evaluateCondition(_ condition: Int, cpu: ARM64CPU) -> Bool {
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("评估条件码: \(condition), 当前标志位: N=\(cpu.flagN), Z=\(cpu.flagZ), C=\(cpu.flagC), V=\(cpu.flagV)")
        }

        var result: Bool

        switch condition {
        case 0:  // EQ (Equal): Z=1
            result = cpu.flagZ
        case 1:  // NE (Not Equal): Z=0
            result = !cpu.flagZ
        case 2:  // CS/HS (Carry Set/Higher or Same): C=1
            result = cpu.flagC
        case 3:  // CC/LO (Carry Clear/Lower): C=0
            result = !cpu.flagC
        case 4:  // MI (Minus/Negative): N=1
            result = cpu.flagN
        case 5:  // PL (Plus/Positive or Zero): N=0
            result = !cpu.flagN
        case 6:  // VS (Overflow): V=1
            result = cpu.flagV
        case 7:  // VC (No Overflow): V=0
            result = !cpu.flagV
        case 8:  // HI (Higher): C=1 AND Z=0
            result = cpu.flagC && !cpu.flagZ
        case 9:  // LS (Lower or Same): C=0 OR Z=1
            result = !cpu.flagC || cpu.flagZ
        case 10: // GE (Greater than or Equal): N=V
            result = cpu.flagN == cpu.flagV
        case 11: // LT (Less Than): N!=V
            result = cpu.flagN != cpu.flagV
        case 12: // GT (Greater Than): Z=0 AND N=V
            result = !cpu.flagZ && (cpu.flagN == cpu.flagV)
        case 13: // LE (Less than or Equal): Z=1 OR N!=V
            result = cpu.flagZ || (cpu.flagN != cpu.flagV)
            if debugMode {
                let detailedResult = "LE条件: Z=\(cpu.flagZ) OR (N!=V) = (N=\(cpu.flagN) != V=\(cpu.flagV)) = \(cpu.flagN != cpu.flagV) => \(result)"
                print(detailedResult)
            }
        case 14: // AL (Always): 总是成立
            result = true
        case 15: // NV (Never): 从不成立
            result = false
        default:
            if debugMode {
                print("不支持的条件码: \(condition)")
            }
            result = false
        }

        if debugMode {
            print("条件 \(condition) 评估结果: \(result ? "成立" : "不成立")")
        }

        return result
    }

    private func executeSUBS(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("执行 SUBS X\(rd), X\(rn), X\(rm)")
            print("操作数: X\(rn)=\(cpu.getRegister(UInt32(rn))), X\(rm)=\(cpu.getRegister(UInt32(rm)))")
        }

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))

        // 使用溢出安全的减法
        let result = operand1.subtractingReportingOverflow(operand2).partialValue

        // 如果目标寄存器不是ZR（31），则存储结果
        if rd != 31 {
            cpu.setRegister(UInt32(rd), value: result)
        }

        // 更新标志位 - SUBS 总是更新标志位
        cpu.updateFlags(result: result, operand1: operand1, operand2: operand2, isAddition: false)

        if debugMode {
            print("SUBS 结果: \(result), 标志位: N=\(cpu.flagN), Z=\(cpu.flagZ), C=\(cpu.flagC), V=\(cpu.flagV)")
        }
    }
}
