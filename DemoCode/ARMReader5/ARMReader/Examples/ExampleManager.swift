import Foundation

// 示例类型枚举
enum ExampleType: Int, CaseIterable {
    case basicArithmetic
    case logicalOperations
    case branching
    case loopAuto
    case loopManual
    case bitwiseOperations    // 新增示例
    case shiftOperations      // 新增示例
    case divisionOperations   // 新增示例
    case simdOperations       // SIMD操作示例

    var title: String {
        switch self {
        case .basicArithmetic: return "1. 基本算术运算"
        case .logicalOperations: return "2. 逻辑运算"
        case .branching: return "3. 分支指令"
        case .loopAuto: return "4. 循环计算 (自动生成)"
        case .loopManual: return "5. 循环计算 (手动编码)"
        case .bitwiseOperations: return "6. 位运算操作"
        case .shiftOperations: return "7. 移位操作"
        case .divisionOperations: return "8. 除法操作"
        case .simdOperations: return "9. SIMD向量运算"
        }
    }
}

// 示例管理器
class ExampleManager {
    private let basicArithmeticExample = BasicArithmeticExample()
    private let logicalOperationsExample = LogicalOperationsExample()
    private let branchingExample = BranchingExample()
    private let loopExample = LoopExample()
    private let manualLoopExample = ManualLoopExample()
    private let bitwiseOperationsExample = BitwiseOperationsExample()
    private let shiftOperationsExample = ShiftOperationsExample()
    private let divisionOperationsExample = DivisionOperationsExample()
    private let simdExample = SIMDExample()
    private let debugMode: Bool

    init(debugMode: Bool) {
        self.debugMode = debugMode
        EmulatorDebugTools.shared.isDebugModeEnabled = debugMode
    }

    // 运行指定的示例
    func runExample(_ type: ExampleType) async -> String {
        // 初始化模拟器
        let emulator = LightEmulator()

        do {
            switch type {
            case .basicArithmetic:
                return try basicArithmeticExample.run(emulator: emulator)
            case .logicalOperations:
                return try logicalOperationsExample.run(emulator: emulator)
            case .branching:
                return try branchingExample.run(emulator: emulator)
            case .loopAuto:
                return try loopExample.run(emulator: emulator)
            case .loopManual:
                return try manualLoopExample.run(emulator: emulator)
            case .bitwiseOperations:
                return try bitwiseOperationsExample.run(emulator: emulator)
            case .shiftOperations:
                return try shiftOperationsExample.run(emulator: emulator)
            case .divisionOperations:
                return try divisionOperationsExample.run(emulator: emulator)
            case .simdOperations:
                return try simdExample.run(emulator: emulator)
            }
        } catch {
            return "❌ 运行错误: \(error.localizedDescription)"
        }
    }

    // 运行所有示例（如果需要）
    func runAllExamples() async -> [ExampleType: String] {
        var results = [ExampleType: String]()

        for example in ExampleType.allCases {
            results[example] = await runExample(example)
        }

        return results
    }
}
