import Foundation

class BranchingExample: BaseExample {
    override func createProgram() -> [UInt32] {
        var program: [UInt32] = []

        // MOV X0, #1
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 1))

        // MOV X1, #2
        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 2))

        // SUBS X0, X0, X1
        program.append(ARM64Assembler.subsRegister(rd: 0, rn: 0, rm: 1))

        // B.NE LABEL1 (如果不等于零，跳转到LABEL1)
        program.append(ARM64Assembler.conditionalBranch(condition: .ne, offsetBytes: 12))

        // MOV X0, #4 (如果条件不成立才执行)
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 4))

        // B LABEL2 (无条件跳转到LABEL2)
        program.append(ARM64Assembler.unconditionalBranch(offsetBytes: 8))

        // LABEL1:
        // MOV X0, #5 (如果条件成立才执行)
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 5))

        // LABEL2:
        // NOP (程序结束标记)
        program.append(0xD503201F)

        return program
    }

    override var expectedResult: UInt64 {
        return 5
    }
}
