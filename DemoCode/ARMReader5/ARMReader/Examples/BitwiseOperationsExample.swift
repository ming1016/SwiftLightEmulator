import Foundation

class BitwiseOperationsExample: BaseExample {
    override func createProgram() -> [UInt32] {
        var program: [UInt32] = []

        // MOV X0, #0xA5 (设置初始值 10100101)
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 0xA5))

        // MOV X1, #0x5A (设置测试值 01011010)
        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 0x5A))

        // ORR X2, X0, X1 (按位或 X2 = X0 | X1 = 0xFF)
        program.append(ARM64Assembler.orrRegister(rd: 2, rn: 0, rm: 1))

        // EOR X3, X0, X1 (按位异或 X3 = X0 ^ X1 = 0xFF)
        program.append(ARM64Assembler.eorRegister(rd: 3, rn: 0, rm: 1))

        // AND X4, X0, X1 (按位与 X4 = X0 & X1 = 0x00)
        program.append(EmulatorDebugTools.shared.createAndInstruction(rd: 4, rn: 0, rm: 1))

        // MOV X5, #0xF0 (设置掩码值)
        program.append(ARM64Assembler.movImmediate(rd: 5, imm16: 0xF0))

        // AND X0, X2, X5 (按位与 X0 = X2 & X5 = 0xF0)
        program.append(EmulatorDebugTools.shared.createAndInstruction(rd: 0, rn: 2, rm: 5))

        // NOP (程序结束标记)
        program.append(0xD503201F)

        return program
    }

    override var expectedResult: UInt64 {
        return 0xF0 // 最终结果: (0xA5 | 0x5A) & 0xF0 = 0xF0
    }
}
