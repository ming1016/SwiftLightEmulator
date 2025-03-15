//
//  ARM64CPU.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

// CPU模拟器 - 负责执行指令和管理寄存器状态
class ARM64CPU {
    // 通用寄存器 (X0-X30)
    private var registers: [UInt64] = Array(repeating: 0, count: 31)
    // SIMD/浮点寄存器 (V0-V31)
    private var simdRegisters: [SIMDRegister] = Array(repeating: SIMDRegister(), count: 32)
    // 程序计数器
    var pc: UInt64 = 0
    // CPU状态寄存器 (PSTATE)
    private var pstate: UInt64 = 0

    // 浮点状态寄存器
    private var fpsr: UInt32 = 0

    // 浮点控制寄存器
    private var fpcr: UInt32 = 0

    // 条件标志位
    var flagN: Bool { return (pstate & 0x80000000) != 0 } // 负数标志
    var flagZ: Bool { return (pstate & 0x40000000) != 0 } // 零标志
    var flagC: Bool { return (pstate & 0x20000000) != 0 } // 进位标志
    var flagV: Bool { return (pstate & 0x10000000) != 0 } // 溢出标志

    // 设置寄存器值
    func setRegister(_ index: UInt32, value: UInt64) {
        guard index < 31 else { return }
        registers[Int(index)] = value
    }

    // 获取寄存器值
    func getRegister(_ index: UInt32) -> UInt64 {
        guard index < 31 else { return 0 }
        return registers[Int(index)]
    }

    // SIMD寄存器操作
    func setSIMDRegister(_ index: UInt32, value: SIMDRegister) {
        guard index < 32 else { return }
        simdRegisters[Int(index)] = value
    }

    func getSIMDRegister(_ index: UInt32) -> SIMDRegister {
        guard index < 32 else { return SIMDRegister() }
        return simdRegisters[Int(index)]
    }

    // SIMD寄存器元素级访问 - 按不同数据大小获取/设置
    func getSIMDElement<T: SIMDElement>(_ index: UInt32, lane: Int, as type: T.Type) -> T? {
        guard index < 32 else { return nil }
        return simdRegisters[Int(index)].getElement(lane: lane, as: type)
    }

    func setSIMDElement<T: SIMDElement>(_ index: UInt32, lane: Int, value: T) {
        guard index < 32 else { return }
        simdRegisters[Int(index)].setElement(lane: lane, value: value)
    }

    // 获取浮点单精度值
    func getFloatRegister(_ index: UInt32) -> Float {
        guard index < 32 else { return 0.0 }
        // 使用SIMD寄存器的低32位作为浮点寄存器
        let simdReg = simdRegisters[Int(index)]
        return simdReg.getElement(lane: 0, as: Float.self)
    }

    // 设置浮点单精度值
    func setFloatRegister(_ index: UInt32, value: Float) {
        guard index < 32 else { return }
        var simdReg = simdRegisters[Int(index)]
        simdReg.setElement(lane: 0, value: value)
        simdRegisters[Int(index)] = simdReg
    }

    // 获取浮点双精度值
    func getDoubleRegister(_ index: UInt32) -> Double {
        guard index < 32 else { return 0.0 }
        let simdReg = simdRegisters[Int(index)]
        return simdReg.getElement(lane: 0, as: Double.self)
    }

    // 设置浮点双精度值
    func setDoubleRegister(_ index: UInt32, value: Double) {
        guard index < 32 else { return }
        var simdReg = simdRegisters[Int(index)]
        simdReg.setElement(lane: 0, value: value)
        simdRegisters[Int(index)] = simdReg
    }

    // 获取浮点状态寄存器
    func getFPSR() -> UInt32 {
        return fpsr
    }

    // 设置浮点状态寄存器
    func setFPSR(_ value: UInt32) {
        fpsr = value
    }

    // 获取浮点控制寄存器
    func getFPCR() -> UInt32 {
        return fpcr
    }

    // 设置浮点控制寄存器
    func setFPCR(_ value: UInt32) {
        fpcr = value
    }

    // 执行指令
    func executeInstruction(_ instruction: UInt32, bus: SystemBus) throws {
        let decoder = InstructionDecoder()
        try decoder.decode(instruction, cpu: self, bus: bus)
    }

    // 更新条件标志位
    func updateFlags(result: UInt64, operand1: UInt64, operand2: UInt64, isAddition: Bool) {
        // 负数标志
        if ((result >> 63) & 1) == 1 {
            pstate |= 0x80000000
        } else {
            pstate &= ~0x80000000
        }

        // 零标志
        if result == 0 {
            pstate |= 0x40000000
        } else {
            pstate &= ~0x40000000
        }

        // 进位和溢出标志（分开处理加法和减法）
        if isAddition {
            // 加法的进位检查
            if result < operand1 {
                pstate |= 0x20000000  // 设置进位标志
            } else {
                pstate &= ~0x20000000 // 清除进位标志
            }

            // 加法的溢出检查（符号位变化）
            let sign1 = (operand1 >> 63) & 1
            let sign2 = (operand2 >> 63) & 1
            let signResult = (result >> 63) & 1

            if (sign1 == sign2) && (sign1 != signResult) {
                pstate |= 0x10000000  // 设置溢出标志
            } else {
                pstate &= ~0x10000000 // 清除溢出标志
            }
        } else {
            // 减法的进位检查（对ARM64，减法的进位实际是"没有借位"）
            if operand1 >= operand2 {
                pstate |= 0x20000000  // 设置进位标志（没有借位）
            } else {
                pstate &= ~0x20000000 // 清除进位标志（有借位）
            }

            // 减法的溢出检查
            let sign1 = (operand1 >> 63) & 1
            let sign2 = (operand2 >> 63) & 1
            let signResult = (result >> 63) & 1

            if (sign1 != sign2) && (sign1 != signResult) {
                pstate |= 0x10000000  // 设置溢出标志
            } else {
                pstate &= ~0x10000000 // 清除溢出标志
            }
        }

        #if DEBUG
        print("标志位更新: N=\(flagN), Z=\(flagZ), C=\(flagC), V=\(flagV)")
        #endif
    }
}
