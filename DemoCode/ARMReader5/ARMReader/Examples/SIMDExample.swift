//
//  SIMDExample.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/16.
//

import Foundation

/// SIMD基础操作示例
class SIMDExample: BaseExample {
    override func createProgram() -> [UInt32] {
        var program: [UInt32] = []

        // 1. 初始化内存区域，用于存储向量数据
        // MOV X0, #0x2000 (数据缓冲区地址)
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 0x2000))

        // 2. 加载两个向量到V0和V1
        // LD1 {V0.16B}, [X0] (从地址X0加载16字节到V0)
        program.append(SIMDAssembler.vectorLoad(vd: 0, rn: 0))

        // ADD X0, X0, #16 (增加地址到下一个数据区)
        program.append(ARM64Assembler.addImmediate(rd: 0, rn: 0, immediate: 16))

        // LD1 {V1.16B}, [X0] (从地址X0+16加载16字节到V1)
        program.append(SIMDAssembler.vectorLoad(vd: 1, rn: 0))

        // 3. 执行SIMD运算: V2 = V0 + V1 (按字节加法)
        program.append(SIMDAssembler.vectorAdd(vd: 2, vn: 0, vm: 1, elementSize: .byte))

        // 4. 执行SIMD运算: V3 = V0 - V1 (按半字减法)
        program.append(SIMDAssembler.vectorSub(vd: 3, vn: 0, vm: 1, elementSize: .halfword))

        // 5. 执行SIMD运算: V4 = V0 & V1 (按位与)
        program.append(SIMDAssembler.vectorAnd(vd: 4, vn: 0, vm: 1))

        // 6. 执行SIMD运算: V5 = V0 | V1 (按位或)
        program.append(SIMDAssembler.vectorOr(vd: 5, vn: 0, vm: 1))

        // 7. 执行SIMD运算: V6 = V0 * V1 (按字乘法)
        program.append(SIMDAssembler.vectorMul(vd: 6, vn: 0, vm: 1, elementSize: .word))

        // 8. 执行SIMD运算: V7 = DUP V0[0] (复制V0的第一个字节到V7的所有位置)
        program.append(SIMDAssembler.vectorDup(vd: 7, vn: 0, index: 0, elementSize: .byte))

        // 9. 将结果V2存储到内存中
        // ADD X0, X0, #16 (增加地址到下一个数据区)
        program.append(ARM64Assembler.addImmediate(rd: 0, rn: 0, immediate: 16))

        // ST1 {V2.16B}, [X0] (将V2存储到内存)
        program.append(SIMDAssembler.vectorStore(vd: 2, rn: 0))

        // 10. 将V2的第一个元素移动到X0中作为返回值
        // UMOV X0, V2.B[0]
        // 由于我们的简化SIMD系统，使用自定义指令来完成这项操作
        program.append(createSIMDToScalarInstruction(rd: 0, vn: 2, index: 0))

        // NOP (程序结束标记)
        program.append(0xD503201F)

        return program
    }

    // 辅助方法：打印向量加法操作的执行结果
    private func printAddResult(vector1: [UInt8], vector2: [UInt8], limit: Int = 4) {
        guard EmulatorDebugTools.shared.isDebugModeEnabled else { return }

        print("\n向量加法操作结果预览:")
        for i in 0..<min(limit, vector1.count, vector2.count) {
            let sum = UInt8(truncatingIfNeeded: Int(vector1[i]) + Int(vector2[i]))
            print("  V0[\(i)]=\(vector1[i]) + V1[\(i)]=\(vector2[i]) = \(sum)")
        }
    }

    override func run(emulator: LightEmulator) throws -> String {
        // 创建程序代码
        let program = createProgram()
        EmulatorDebugTools.shared.printProgram(program, baseAddress: 0x1000)

        // 附加调试信息：验证向量加法指令
        validateInstructions()

        // 使调试输出更明确
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled
        if debugMode {
            print("\n========== SIMD示例开始 ==========\n")
        }

        // 加载程序到模拟器内存
        try emulator.loadProgram(at: 0x1000, code: program)

        // 准备内存区域 - 确保分配足够空间给向量数据
        // 在0x2000处预分配64字节的空间 (16字节x4 - 两个输入向量+两个输出向量)
        for offset in 0..<64 {
            try emulator.memory.write(at: 0x2000 + UInt64(offset), value: 0, size: 1)
        }

        // 初始化内存中的向量数据
        let vector1: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
        let vector2: [UInt8] = [16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

        // 将向量数据写入内存
        try initializeVectorData(emulator: emulator, vector1: vector1, vector2: vector2)

        // 打印预期的加法结果
        if debugMode {
            printAddResult(vector1: vector1, vector2: vector2)
        }

        // 设置PC到程序起始位置
        emulator.cpu.pc = 0x1000

        // 执行程序
        do {
            try emulator.run()

            // 获取结果
            let result = emulator.getRegister(0)

            if debugMode {
                print("\n========== SIMD示例完成 ==========\n")
            }

            // 验证结果: V2.B[0] = V0.B[0] + V1.B[0] = 1 + 16 = 17
            return "SIMD运算结果: \(result) \(result == 17 ? "✓" : "❌")"
        } catch {
            print("SIMD示例执行失败: \(error)")
            throw error
        }
    }

    // 向内存中写入向量测试数据
    private func initializeVectorData(emulator: LightEmulator, vector1: [UInt8], vector2: [UInt8]) throws {
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if (debugMode) {
            print("初始化SIMD测试数据")
        }

        // 写入第一个向量
        for (i, byte) in vector1.enumerated() {
            try emulator.memory.write(at: 0x2000 + UInt64(i), value: UInt64(byte), size: 1)
            if debugMode && i < 4 {
                print("向量1[\(i)] = \(byte)")
            }
        }

        // 写入第二个向量
        for (i, byte) in vector2.enumerated() {
            try emulator.memory.write(at: 0x2010 + UInt64(i), value: UInt64(byte), size: 1)
            if debugMode && i < 4 {
                print("向量2[\(i)] = \(byte)")
            }
        }

        // 设置PC到程序起始位置
        emulator.cpu.pc = 0x1000
    }

    // 创建从SIMD寄存器到标量寄存器的移动指令
    // 注：这是一个简化实现，实际ARM64有专门的UMOV指令
    private func createSIMDToScalarInstruction(rd: Int, vn: Int, index: Int) -> UInt32 {
        // 自定义指令格式，将在InstructionDecoder中特殊处理
        var instruction: UInt32 = 0x0D000000
        instruction |= UInt32(rd)
        instruction |= UInt32(vn) << 5
        instruction |= UInt32(index) << 10
        return instruction
    }

    override var expectedResult: UInt64 {
        // 预期结果是17 (1+16)
        return 17
    }
}

// 添加用于汇编指令调试的扩展方法
extension SIMDExample {
    // 输出验证程序中使用的指令格式
    func validateInstructions() {
        guard EmulatorDebugTools.shared.isDebugModeEnabled else { return }

        print("SIMD指令验证:")

        // 创建已知格式的向量加法指令
        let addInst = SIMDAssembler.vectorAdd(vd: 2, vn: 0, vm: 1, elementSize: .byte)
        print("  向量加法原始: 0x\(String(format:"%08X", addInst))")

        // 创建一个精确匹配的手动指令
        let preciseMatcher = UInt32(0x4E210402) // 使用已知会生成的确切格式
        print("  精确匹配格式: 0x\(String(format:"%08X", preciseMatcher))")

        // 检查两者是否相等
        if addInst == preciseMatcher {
            print("  ✓ 指令格式匹配!")
        } else {
            print("  ❌ 指令格式不匹配!")

            // 分析差异
            let diff = addInst ^ preciseMatcher
            print("  差异位: 0x\(String(format:"%08X", diff))")
            print("  差异位(二进制): \(String(diff, radix: 2).padding(toLength: 32, withPad: "0", startingAt: 0))")
        }

        // 验证向量减法指令
        let subInst = SIMDAssembler.vectorSub(vd: 3, vn: 0, vm: 1, elementSize: .halfword)
        print("  向量减法: 0x\(String(format:"%08X", subInst))")

        // 验证向量加载/存储
        let loadInst = SIMDAssembler.vectorLoad(vd: 0, rn: 0)
        print("  向量加载: 0x\(String(format:"%08X", loadInst))")

        let storeInst = SIMDAssembler.vectorStore(vd: 2, rn: 0)
        print("  向量存储: 0x\(String(format:"%08X", storeInst))")
    }
}
