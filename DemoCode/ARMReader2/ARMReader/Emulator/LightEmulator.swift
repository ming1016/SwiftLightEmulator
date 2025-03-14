//
//  LightEmulator.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//
import Foundation

// 模拟器核心架构 - 基于QEMU风格的设计
class LightEmulator {
    // CPU核心
    private var cpu: ARM64CPU
    // 内存管理
    private var memory: MemoryManager
    // 系统总线
    private var systemBus: SystemBus
    // 设备管理器
    private var deviceManager: DeviceManager

    init(memorySize: UInt64 = 1024 * 1024) { // 默认 1MB 内存
        self.memory = MemoryManager(size: memorySize)
        self.cpu = ARM64CPU()
        self.systemBus = SystemBus()
        self.deviceManager = DeviceManager()

        // 初始化总线连接
        systemBus.connectMemory(memory)
        systemBus.connectCPU(cpu)
    }

    // 加载程序
    func loadProgram(at address: UInt64, code: [UInt32]) throws {
        try memory.write(at: address, data: code)
        cpu.pc = address
    }

    // 执行单个指令
    func executeInstruction() throws {
        let instruction = try memory.readInstruction(at: cpu.pc)
        try cpu.executeInstruction(instruction, bus: systemBus)
        cpu.pc += 4 // 移动到下一条指令
    }

    func setRegister(_ index: UInt32, value: UInt64) {
        cpu.setRegister(index, value: value)
    }

    func getRegister(_ index: UInt32) -> UInt64 {
        return cpu.getRegister(index)
    }

    // 运行程序
    func run() throws {
        var instructionCount = 0
        let maxInstructions = 1000 // 防止无限循环

        while instructionCount < maxInstructions {
            let instruction = try memory.readInstruction(at: cpu.pc)
            if instruction == 0xD503201F { // NOP 指令，用作程序结束标记
                break
            }
            try cpu.executeInstruction(instruction, bus: systemBus)
            cpu.pc += 4
            instructionCount += 1
        }
    }
}
