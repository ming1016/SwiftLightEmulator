//
//  SystemBus.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//
import Foundation

// 系统总线 - 连接CPU和内存/设备
class SystemBus {
    private var memory: MemoryManager?
    private var cpu: ARM64CPU?
    private var devices: [UInt64: DeviceController] = [:]

    func connectMemory(_ memoryManager: MemoryManager) {
        self.memory = memoryManager
    }

    func connectCPU(_ cpu: ARM64CPU) {
        self.cpu = cpu
    }

    func registerDevice(at baseAddress: UInt64, device: DeviceController) {
        devices[baseAddress] = device
    }

    // 读取内存
    func read(at address: UInt64, size: Int = 8) throws -> UInt64 {
        // 检查是否为设备映射地址
        for (baseAddr, device) in devices {
            if address >= baseAddr && address < baseAddr + device.size {
                return try device.read(at: address - baseAddr)
            }
        }

        // 普通内存访问
        guard let memory = memory else {
            throw EmulatorError.deviceError(message: "内存未连接")
        }

        return try memory.read(at: address, size: size)
    }

    // 写入内存
    func write(at address: UInt64, value: UInt64, size: Int = 8) throws {
        // 检查是否为设备映射地址
        for (baseAddr, device) in devices {
            if address >= baseAddr && address < baseAddr + device.size {
                try device.write(at: address - baseAddr, value: value)
                return
            }
        }

        // 普通内存访问
        guard let memory = memory else {
            throw EmulatorError.deviceError(message: "内存未连接")
        }

        try memory.write(at: address, value: value, size: size)
    }

    func getMemory() -> MemoryManager? {
        return memory
    }
}
