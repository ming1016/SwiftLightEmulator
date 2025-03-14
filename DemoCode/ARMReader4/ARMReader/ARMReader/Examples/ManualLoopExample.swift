import Foundation

class ManualLoopExample: BaseExample {
    override func run(emulator: LightEmulator) throws -> String {
        let program = createProgram()
        EmulatorDebugTools.shared.printProgram(program, baseAddress: 0x1000, withDescription: EmulatorDebugTools.shared.isDebugModeEnabled)

        if EmulatorDebugTools.shared.isDebugModeEnabled {
            EmulatorDebugTools.shared.validateLoopProgram(program)
        }

        try emulator.loadProgram(at: 0x1000, code: program)
        try emulator.run()

        let result = emulator.getRegister(0)

        if result == 10 {
            return "结果: \(result) ✓ (1+2+3+4=10)"
        } else {
            return "结果: \(result) ❌ (预期: 10)"
        }
    }

    override func createProgram() -> [UInt32] {
        var program: [UInt32] = []

        // 0x1000: MOV X0, #0 (累加器初始化为0)
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 0))

        // 0x1004: MOV X1, #1 (循环计数器初始值)
        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 1))

        // 0x1008: MOV X2, #4 (最大循环次数值)
        program.append(ARM64Assembler.movImmediate(rd: 2, imm16: 4))

        // LOOP_START (0x100C):
        // 0x100C: ADD X0, X0, X1 (累加当前值)
        program.append(ARM64Assembler.addRegister(rd: 0, rn: 0, rm: 1))

        // 0x1010: ADD X1, X1, #1 (递增计数器)
        program.append(ARM64Assembler.addImmediate(rd: 1, rn: 1, immediate: 1))

        // 0x1014: SUBS XZR, X1, X2 (比较 X1 和 X2)
        program.append(ARM64Assembler.subsRegister(rd: 31, rn: 1, rm: 2))

        // 0x1018: B.LE -12 (如果 X1<=X2 跳回 0x100C)
        program.append(ARM64Assembler.conditionalBranch(condition: .le, offsetBytes: -12))

        // 0x101C: NOP (程序结束)
        program.append(0xD503201F)

        return program
    }

    override var expectedResult: UInt64 {
        return 10 // 1+2+3+4=10
    }
}
