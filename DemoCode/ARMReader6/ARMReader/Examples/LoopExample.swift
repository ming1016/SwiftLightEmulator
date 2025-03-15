import Foundation

class LoopExample: BaseExample {
    override func run(emulator: LightEmulator) throws -> String {
        let program = ARM64Assembler.createLoopProgram()
        EmulatorDebugTools.shared.validateBranchOffset(program[6], expectedOffset: -12)

        try emulator.loadProgram(at: 0x1000, code: program)
        try emulator.run()

        let result = emulator.getRegister(0)

        if result == 10 {
            return "结果: \(result) ✓ (1+2+3+4=10)"
        } else {
            return "结果: \(result) ❌ (预期: 10)"
        }
    }

    // 使用ARM64Assembler.createLoopProgram()创建程序
    override func createProgram() -> [UInt32] {
        return ARM64Assembler.createLoopProgram()
    }

    override var expectedResult: UInt64 {
        return 10 // 1+2+3+4=10
    }
}
