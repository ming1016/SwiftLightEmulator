import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ContentView: View {
    var body: some View {
        Text("计算结果将在控制台显示")
            .padding()
            .onAppear {
                do {
                    let emulator = LightEmulator()

                    // 修改后的示例程序：计算 5 + 3
                    let program: [UInt32] = [
                        0x91000420,  // ADD X0, X1, X2
                        0xD503201F   // NOP (用作程序结束标记)
                    ]

                    try emulator.loadProgram(at: 0x1000, code: program)

                    emulator.setRegister(1, value: 5)  // X1 = 5
                    emulator.setRegister(2, value: 3)  // X2 = 3

                    try emulator.run()

                    // 打印结果
                    print("计算结果: \(emulator.getRegister(0))")
                } catch {
                    print("模拟器错误: \(error)")
                }
            }
    }
}

/// 轻量级 ARM64 模拟器
class LightEmulator {
    // 寄存器状态
    private var registers: [UInt64] = Array(repeating: 0, count: 31)
    // 程序计数器
    private var pc: UInt64 = 0
    // 内存管理
    private var memory: MemoryManager

    init(memorySize: UInt64 = 1024 * 1024) { // 默认 1MB 内存
        self.memory = MemoryManager(size: memorySize)
    }

    // 加载程序
    func loadProgram(at address: UInt64, code: [UInt32]) throws {
        try memory.write(at: address, data: code)
        pc = address
    }

    // 执行单个指令
    func executeInstruction() throws {
        let instruction = try memory.readInstruction(at: pc)
        try decode(instruction)
        pc += 4 // 移动到下一条指令
    }

    func setRegister(_ index: UInt32, value: UInt64) {
        guard index < 31 else {
            return // 忽略无效的寄存器索引
        }
        registers[Int(index)] = value
    }

    // 添加获取寄存器值的方法
    func getRegister(_ index: UInt32) -> UInt64 {
        guard index < 31 else { return 0 }
        return registers[Int(index)]
    }

    // 修改 run 方法，添加终止条件
    func run() throws {
        var instructionCount = 0
        let maxInstructions = 1000 // 防止无限循环

        while instructionCount < maxInstructions {
            let instruction = try memory.readInstruction(at: pc)
            if instruction == 0xD503201F { // NOP 指令，用作程序结束标记
                break
            }
            try decode(instruction)
            pc += 4
            instructionCount += 1
        }
    }
}


class MemoryManager {
    private var memory: [UInt8]

    init(size: UInt64) {
        memory = Array(repeating: 0, count: Int(size))
    }

    func read(at address: UInt64, size: Int) throws -> [UInt8] {
        guard address + UInt64(size) <= UInt64(memory.count) else {
            throw EmulatorError.memoryOutOfBounds
        }
        return Array(memory[Int(address)..<Int(address)+size])
    }

    func write(at address: UInt64, data: [UInt32]) throws {
        guard address + UInt64(data.count * 4) <= UInt64(memory.count) else {
            throw EmulatorError.memoryOutOfBounds
        }

        for (i, word) in data.enumerated() {
            let addr = Int(address) + i * 4
            memory[addr] = UInt8(word & 0xFF)
            memory[addr + 1] = UInt8((word >> 8) & 0xFF)
            memory[addr + 2] = UInt8((word >> 16) & 0xFF)
            memory[addr + 3] = UInt8((word >> 24) & 0xFF)
        }
    }

    func readInstruction(at address: UInt64) throws -> UInt32 {
        let bytes = try read(at: address, size: 4)
        return UInt32(bytes[0]) |
               UInt32(bytes[1]) << 8 |
               UInt32(bytes[2]) << 16 |
               UInt32(bytes[3]) << 24
    }
}

extension LightEmulator {
    // 修改 decode 方法
    func decode(_ instruction: UInt32) throws {
        let op31_24 = (instruction >> 24) & 0xFF
        let op23_16 = (instruction >> 16) & 0xFF

        if op31_24 == 0x91 { // ADD 指令
            let rd = Int(instruction & 0x1F)
            let rn = Int((instruction >> 5) & 0x1F)
            let rm = Int((instruction >> 16) & 0x1F)
            registers[rd] = registers[rn] + registers[rm]
        } else {
            throw EmulatorError.unsupportedInstruction(UInt8(op31_24))
        }
    }
}

enum EmulatorError: Error {
    case memoryOutOfBounds
    case unsupportedInstruction(UInt8)
    case invalidAddress
    case systemCallError(String)
}

extension LightEmulator {
    func handleSystemCall(_ number: UInt64) throws {
        switch number {
        case 1: // 打印寄存器值
            let value = registers[0] // X0 寄存器值
            print("输出: \(value)")

        case 2: // 退出程序
            throw EmulatorError.systemCallError("程序结束")

        default:
            throw EmulatorError.systemCallError("未知系统调用: \(number)")
        }
    }
}


