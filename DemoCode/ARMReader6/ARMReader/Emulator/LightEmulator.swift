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
    var cpu: ARM64CPU
    // 内存管理
    var memory: MemoryManager // 修改为public以便示例访问
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
        // 开始性能监控
        PerformanceMetrics.shared.startMeasuring()

        var instructionCount = 0
        let maxInstructions = 1000 // 防止无限循环
        var visitedAddresses = Set<UInt64>() // 记录已执行过的地址，用于检测无限循环
        var loopCount = 0 // 循环计数
        var loopEntries = Set<UInt64>() // 记录所有循环入口点

        // 判断是否处于调试模式
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        while instructionCount < maxInstructions {
            // 检查PC是否在有效内存范围内
            if !memory.isValidAddress(cpu.pc) {
                throw EmulatorError.programCounterOutOfBounds(address: cpu.pc)
            }

            // 检查PC是否4字节对齐
            if cpu.pc % 4 != 0 {
                throw EmulatorError.programCounterOutOfBounds(address: cpu.pc)
            }

            // 获取当前重要寄存器值，用于调试
            let x0 = cpu.getRegister(0)
            let x1 = cpu.getRegister(1)
            let x2 = cpu.getRegister(2)

            // 循环检测 - 用于跟踪循环执行情况
            if cpu.pc == 0x100C {
                if visitedAddresses.contains(cpu.pc) {
                    // 这是一个循环迭代
                    loopCount += 1
                    if debugMode {
                        print("循环迭代 #\(loopCount): X0=\(x0) (累加器), X1=\(x1) (计数器), X2=\(x2) (最大值)")
                        print("  预期累加结果: \(x0) + \(x1) = \(x0 + x1)")
                    }
                } else {
                    // 首次进入循环点
                    loopEntries.insert(cpu.pc)
                    if debugMode {
                        print("首次进入循环点: 0x\(String(format: "%016X", cpu.pc))")
                    }
                }
            }

            visitedAddresses.insert(cpu.pc)

            // 读取指令
            let instruction: UInt32
            do {
                instruction = try memory.readInstruction(at: cpu.pc)

                // 额外检查指令是否为全0
                if instruction == 0 {
                    throw EmulatorError.unsupportedInstructionFormat(
                        format: "0x00000000",
                        opcode: 0,
                        details: "空指令(全0)，可能是跳转地址计算错误导致，地址: 0x\(String(format: "%016X", cpu.pc))"
                    )
                }
            } catch {
                if debugMode {
                    print("错误: 从地址 0x\(String(format: "%016X", cpu.pc)) 读取指令失败")
                }
                throw error
            }

            // 获取当前指令地址（用于调试）
            if debugMode {
                print("执行位置: 0x\(String(format: "%016X", cpu.pc)), 指令: 0x\(String(format: "%08X", instruction))")
            }

            // 检测浮点指令
            if (instruction >> 24) == 0x1E {
                let rd = Int(instruction & 0x1F)
                let rn = Int((instruction >> 5) & 0x1F)
                let rm = Int((instruction >> 16) & 0x1F)
                if debugMode {
                    print("浮点指令解析: rd=\(rd), rn=\(rn), rm=\(rm)")
                }
            }

            if debugMode {
                print("执行位置: 0x\(String(format: "%016X", cpu.pc)), 指令: 0x\(String(format: "%08X", instruction))")
            }

            // 检查是否为NOP作为程序结束标记
            if instruction == 0xD503201F { // NOP 指令，用作程序结束标记
                break
            }

            // 保存当前PC，因为执行分支指令会改变PC
            let currentPC = cpu.pc

            // 执行指令
            do {
                try cpu.executeInstruction(instruction, bus: systemBus)
            } catch {
                print("错误: 在地址 0x\(String(format: "%016X", cpu.pc)) 执行指令 0x\(String(format: "%08X", instruction)) 失败")
                throw error
            }

            // 如果是分支指令并且在目标地址为0x100C，可能是循环的返回
            if cpu.pc == 0x100C && currentPC == 0x1018 && debugMode {
                print("循环分支: 从0x1018跳回0x100C, X0=\(x0), X1=\(x1), X2=\(x2)")
            }

            // 如果是分支指令并且跳转回了之前的位置，这可能是一个循环
            if cpu.pc < currentPC && loopEntries.contains(cpu.pc) {
                PerformanceMetrics.shared.incrementLoops()
                if debugMode {
                    print("循环跳转: 从0x\(String(format: "%016X", currentPC)) 回到 0x\(String(format: "%016X", cpu.pc))")
                    print("寄存器状态: X0=\(x0), X1=\(x1), X2=\(x2)")
                }
            }

            // 如果是分支指令跳转，记录分支跳转次数
            if cpu.pc != currentPC + 4 && cpu.pc != currentPC {
                PerformanceMetrics.shared.incrementBranches()
            }

            // 如果是ADD指令作用于X1（计数器），记录计数器变化
            if (instruction & 0xFF000000) == 0x91000000 && debugMode {
                let rd = instruction & 0x1F
                let rn = (instruction >> 5) & 0x1F
                let imm12 = (instruction >> 10) & 0xFFF

                // 检查是否是计数器递增指令
                if rd == 1 && rn == 1 {
                    let oldValue = x1
                    let newValue = oldValue + UInt64(imm12)
                    print("监测ADD immediate: X\(rd) += \(imm12), 旧值=\(oldValue), 预期新值=\(newValue)")
                }
            }

            // 如果是普通指令（没有改变PC），移动到下一条指令
            if cpu.pc == currentPC {
                cpu.pc += 4
            }

            // 在执行完指令后立即验证寄存器状态是否符合预期
            if cpu.pc == 0x1014 && instruction == 0x91000421 && debugMode {
                // 刚执行完递增计数器指令，检查X1值是否正确递增
                let newX1 = cpu.getRegister(1)
                let oldX1 = x1
                print("递增计数器后状态检查: X1=\(newX1), 期望值=\(oldX1+1)")
                if newX1 != oldX1 + 1 {
                    print("⚠️ X1递增异常! 预期值为\(oldX1+1)，实际值为\(newX1)")
                }
            }

            instructionCount += 1
            PerformanceMetrics.shared.incrementInstructions()
        }

        if instructionCount >= maxInstructions {
            print("警告: 达到最大指令执行次数限制(\(maxInstructions))，可能存在无限循环")
            throw EmulatorError.deviceError(message: "可能存在无限循环，执行了\(instructionCount)条指令")
        }

        // 结束性能监控
        PerformanceMetrics.shared.stopMeasuring()

        // 执行结束，只在调试模式下显示最终寄存器状态
        if debugMode {
            let finalX0 = cpu.getRegister(0)
            let finalX1 = cpu.getRegister(1)
            let finalX2 = cpu.getRegister(2)
            print("程序执行完毕: X0=\(finalX0) (累加结果), X1=\(finalX1), X2=\(finalX2), 循环执行\(loopCount)次")

            // 验证累加结果是否正确
            if loopCount > 0 && finalX2 == 4 {
                let expected = (1 + Int(finalX2)) * Int(finalX2) / 2 // 高斯求和公式
                print("验证: 从1到\(finalX2)的和 = \(expected), 实际值 = \(finalX0)")
                if expected == Int(finalX0) {
                    print("✓ 计算结果正确!")
                } else {
                    print("✗ 计算结果错误! 应为\(expected)，实际为\(finalX0)")
                }
            }

            print("程序成功执行完毕，共执行\(instructionCount)条指令")
            print(PerformanceMetrics.shared.getStatisticsString())
        }
    }
}
