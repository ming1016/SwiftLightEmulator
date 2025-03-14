import Foundation

class ShiftOperationsExample: BaseExample {
    override func createProgram() -> [UInt32] {
        var program: [UInt32] = []

        // MOV X0, #5 (设置初始值)
        program.append(ARM64Assembler.movImmediate(rd: 0, imm16: 5))

        // MOV X1, #3 (设置移位量)
        program.append(ARM64Assembler.movImmediate(rd: 1, imm16: 3))

        // LSL X2, X0, X1 (X2 = X0 << X1 = 5 << 3 = 40)
        program.append(ARM64Assembler.lslRegister(rd: 2, rn: 0, rm: 1))

        // LSR X3, X2, X1 (X3 = X2 >> X1 = 40 >> 3 = 5)
        program.append(ARM64Assembler.lsrRegister(rd: 3, rn: 2, rm: 1))

        // LSL X0, X0, #4 (X0 = X0 << 4 = 5 << 4 = 80)
        program.append(ARM64Assembler.lslImmediate(rd: 0, rn: 0, shift: 4))

        // LSR X0, X0, #2 (X0 = X0 >> 2 = 80 >> 2 = 20)
        program.append(ARM64Assembler.lsrImmediate(rd: 0, rn: 0, shift: 2))

        // NOP (程序结束标记)
        program.append(0xD503201F)

        return program
    }

    override var expectedResult: UInt64 {
        return 20 // 最终结果: (5 << 4) >> 2 = 20
    }
}
