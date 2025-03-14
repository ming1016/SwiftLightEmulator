import Foundation

class LogicalOperationsExample: BaseExample {
    override func createProgram() -> [UInt32] {
        var program: [UInt32] = []

        // MOV X0, #10
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 10))

        // MOV X1, #3
        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 3))

        // AND X0, X0, X1
        program.append(EmulatorDebugTools.shared.createAndInstruction(rd: 0, rn: 0, rm: 1))

        // NOP (程序结束标记)
        program.append(0xD503201F)

        return program
    }

    override var expectedResult: UInt64 {
        return 2 // 10 & 3 = 2
    }
}
