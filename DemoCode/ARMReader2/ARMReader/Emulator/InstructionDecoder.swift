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

        // 为调试添加指令信息输出
        #if DEBUG
        print("解码指令: 0x\(String(format: "%08X", instruction)) 操作码: 0x\(String(format: "%02X", op31_24))")
        #endif

        switch op31_24 {
        case 0x91, 0x8B: // ADD 指令
            executeADD(instruction, cpu: cpu)

        case 0xCB: // SUB 指令
            executeSUB(instruction, cpu: cpu)

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

        case 0xD2: // MOV (immediate)
            executeMOV(instruction, cpu: cpu)

        case 0xD5: // 系统指令
            // 目前仅支持NOP
            if instruction != 0xD503201F {
                throw EmulatorError.unsupportedInstruction(UInt8(op31_24))
            }

        default:
            throw EmulatorError.unsupportedInstruction(UInt8(op31_24))
        }
    }

    private func executeADD(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))
        let result = operand1 + operand2

        cpu.setRegister(UInt32(rd), value: result)
        cpu.updateFlags(result: result, operand1: operand1, operand2: operand2, isAddition: true)
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

    private func executeMUL(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)           // 目标寄存器 [4:0]
        let rn = Int((instruction >> 5) & 0x1F)    // 第一个源寄存器 [9:5]
        let rm = Int((instruction >> 16) & 0x1F)   // 第二个源寄存器 [20:16]

        #if DEBUG
        print("执行 MUL X\(rd), X\(rn), X\(rm)")
        print("操作数: X\(rn)=\(cpu.getRegister(UInt32(rn))), X\(rm)=\(cpu.getRegister(UInt32(rm)))")
        #endif

        let operand1 = cpu.getRegister(UInt32(rn))
        let operand2 = cpu.getRegister(UInt32(rm))
        let result = operand1 * operand2

        cpu.setRegister(UInt32(rd), value: result)

        #if DEBUG
        print("结果: X\(rd)=\(result)")
        #endif
    }

    private func executeAND(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)

        let result = cpu.getRegister(UInt32(rn)) & cpu.getRegister(UInt32(rm))
        cpu.setRegister(UInt32(rd), value: result)
    }

    private func executeMOV(_ instruction: UInt32, cpu: ARM64CPU) {
        let rd = Int(instruction & 0x1F)
        let imm16 = (instruction >> 5) & 0xFFFF
        cpu.setRegister(UInt32(rd), value: UInt64(imm16))
    }
}
