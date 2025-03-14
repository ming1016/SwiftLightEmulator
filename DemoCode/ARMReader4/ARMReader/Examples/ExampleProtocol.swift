import Foundation

// 示例协议
protocol EmulatorExample {
    func run(emulator: LightEmulator) throws -> String
    func createProgram() -> [UInt32]
    var expectedResult: UInt64 { get }
}

// 基础示例实现
class BaseExample: EmulatorExample {
    func run(emulator: LightEmulator) throws -> String {
        let program = createProgram()
        EmulatorDebugTools.shared.printProgram(program, baseAddress: 0x1000)

        try emulator.loadProgram(at: 0x1000, code: program)
        try emulator.run()

        let result = emulator.getRegister(0)

        if result == expectedResult {
            return "结果: \(result) ✓"
        } else {
            return "结果: \(result) ❌ (预期: \(expectedResult))"
        }
    }

    func createProgram() -> [UInt32] {
        // 子类必须重写
        return []
    }

    var expectedResult: UInt64 {
        // 子类必须重写
        return 0
    }
}
