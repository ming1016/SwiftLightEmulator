import Foundation

class DivisionOperationsExample: BaseExample {
    override func createProgram() -> [UInt32] {
        var program: [UInt32] = []

        // MOV X0, #100 (设置被除数)
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 100))

        // MOV X1, #4 (设置除数)
        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 4))

        // UDIV X2, X0, X1 (无符号除法 X2 = X0 / X1 = 100 / 4 = 25)
        program.append(ARM64Assembler.udiv(rd: 2, rn: 0, rm: 1))

        // MOV X3, #3 (设置另一个除数)
        program.append(ARM64Assembler.movImmediate(rd: 3, imm16: 3))

        // UDIV X0, X0, X3 (无符号除法 X0 = X0 / X3 = 100 / 3 = 33)
        program.append(ARM64Assembler.udiv(rd: 0, rn: 0, rm: 3))

        // 创建负数 -10 的正确方法：
        // 1. 首先设置为0
        program.append(ARM64Assembler.movImmediate(rd: 4, imm16: 0))
        // 2. 然后减去10
        program.append(ARM64Assembler.subImmediate(rd: 4, rn: 4, immediate: 10)) // X4 = 0 - 10 = -10

        // MOV X5, #2 (设置除数)
        program.append(ARM64Assembler.movImmediate(rd: 5, imm16: 2))

        // SDIV X6, X4, X5 (有符号除法 X6 = X4 / X5 = -10 / 2 = -5)
        program.append(ARM64Assembler.sdiv(rd: 6, rn: 4, rm: 5))

        // NOP (程序结束标记)
        program.append(0xD503201F)

        return program
    }

    override var expectedResult: UInt64 {
        return 33 // 最终结果: 100 / 3 = 33
    }

    // 替换默认的run方法，以便我们可以验证更多寄存器的值
    override func run(emulator: LightEmulator) throws -> String {
        let program = createProgram()
        EmulatorDebugTools.shared.printProgram(program, baseAddress: 0x1000)

        try emulator.loadProgram(at: 0x1000, code: program)
        try emulator.run()

        let result = emulator.getRegister(0)
        let udivResult = emulator.getRegister(2)
        let sdivResult = emulator.getRegister(6)

        // 验证所有除法结果
        let udivCorrect = udivResult == 25 // 100/4 = 25
        let mainCorrect = result == 33 // 100/3 = 33
        let sdivCorrect = Int64(bitPattern: sdivResult) == -5 // -10/2 = -5

        if udivCorrect && mainCorrect && sdivCorrect {
            return "结果: X0=\(result) (100/3), X2=\(udivResult) (100/4), X6=\(sdivResult) (有符号-10/2) ✓"
        } else {
            var errorMsg = "结果错误: "
            if !mainCorrect { errorMsg += "X0=\(result) (应为33), " }
            if !udivCorrect { errorMsg += "X2=\(udivResult) (应为25), " }
            if !sdivCorrect { errorMsg += "X6=\(sdivResult) (应为-5)" }
            return errorMsg + " ❌"
        }
    }
}
