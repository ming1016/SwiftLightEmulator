//
//  SystemBus.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//
import Foundation

// 系统总线 - 连接CPU、内存和设备
class SystemBus {
    private weak var memory: MemoryManager?
    private weak var cpu: ARM64CPU?
    private var devices: [UInt64: Device] = [:]

    func connectMemory(_ memory: MemoryManager) {
        self.memory = memory
    }

    func connectCPU(_ cpu: ARM64CPU) {
        self.cpu = cpu
    }

    func registerDevice(_ device: Device, atAddress: UInt64) {
        devices[atAddress] = device
    }

    // 内存读取
    func read(at address: UInt64, size: Int) throws -> [UInt8] {
        // 检查设备映射
        for (baseAddr, device) in devices {
            if address >= baseAddr && address < baseAddr + device.size {
                return device.read(at: address - baseAddr, size: size)
            }
        }

        // 如果不是设备，尝试从内存读取
        guard let memory = memory else {
            throw EmulatorError.systemCallError("总线未连接到内存")
        }

        return try memory.read(at: address, size: size)
    }

    // 内存写入
    func write(at address: UInt64, data: [UInt8]) throws {
        // 检查设备映射
        for (baseAddr, device) in devices {
            if address >= baseAddr && address < baseAddr + device.size {
                device.write(at: address - baseAddr, data: data)
                return
            }
        }

        // 如果不是设备，尝试写入内存
        guard let memory = memory else {
            throw EmulatorError.systemCallError("总线未连接到内存")
        }

        if memory.isReadOnlyRegion(address) {
            throw EmulatorError.memoryProtectionViolation
        }

        // 实际写入内存的代码需要修改
        // 这里需要将通用的data:[UInt8]转换为当前内存管理器需要的格式
    }
}
