//
//  MemoryManager.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//
import Foundation

// 内存管理器 - 负责内存分配和访问
class MemoryManager {
    // 内存大小
    let size: UInt64
    // 内存数据
    private var memory: [UInt8]
    private var memoryMap: [MemoryRegion] = []

    struct MemoryRegion {
        let start: UInt64
        let size: UInt64
        let isReadOnly: Bool
        let name: String
    }

    init(size: UInt64) {
        self.size = size
        self.memory = Array(repeating: 0, count: Int(size))
        // 创建默认内存映射
        memoryMap.append(MemoryRegion(start: 0, size: size, isReadOnly: false, name: "RAM"))
    }

    // 从内存读取数据
    func read(at address: UInt64, size: Int = 8) throws -> UInt64 {
        guard address + UInt64(size) <= self.size else {
            throw EmulatorError.memoryAccessOutOfBounds(address: address)
        }

        var result: UInt64 = 0
        for i in 0..<size {
            result |= UInt64(memory[Int(address) + i]) << (i * 8)
        }
        return result
    }

    // 读取指令 (始终为32位)
    func readInstruction(at address: UInt64) throws -> UInt32 {
        // 检查地址对齐
        if address % 4 != 0 {
            throw EmulatorError.memoryAccessOutOfBounds(address: address)
        }

        // 检查地址边界
        guard isValidAddress(address) && address + 4 <= self.size else {
            throw EmulatorError.memoryAccessOutOfBounds(address: address)
        }

        let value = try read(at: address, size: 4)
        return UInt32(value & 0xFFFFFFFF)
    }

    // 向内存写入单个值
    func write(at address: UInt64, value: UInt64, size: Int = 8) throws {
        guard address + UInt64(size) <= self.size else {
            throw EmulatorError.memoryAccessOutOfBounds(address: address)
        }

        for i in 0..<size {
            memory[Int(address) + i] = UInt8((value >> (i * 8)) & 0xFF)
        }
    }

    // 写入一组指令
    func write(at address: UInt64, data: [UInt32]) throws {
        guard address + UInt64(data.count * 4) <= self.size else {
            throw EmulatorError.memoryAccessOutOfBounds(address: address)
        }

        for (index, instruction) in data.enumerated() {
            let addr = address + UInt64(index * 4)
            try write(at: addr, value: UInt64(instruction), size: 4)
        }
    }

    // 添加内存区域映射
    func addMemoryRegion(start: UInt64, size: UInt64, isReadOnly: Bool, name: String) {
        memoryMap.append(MemoryRegion(start: start, size: size, isReadOnly: isReadOnly, name: name))
    }

    // 检查地址是否有效
    func isValidAddress(_ address: UInt64) -> Bool {
        // 基本验证：地址在内存范围内
        if address < self.size {
            return true
        }

        // 额外检查：如果有特定映射，检查映射区域
        for region in memoryMap {
            if address >= region.start && address < region.start + region.size {
                return true
            }
        }

        return false
    }

    // 检查是否为只读区域
    func isReadOnlyRegion(_ address: UInt64) -> Bool {
        for region in memoryMap {
            if address >= region.start && address < region.start + region.size {
                return region.isReadOnly
            }
        }
        return false
    }
}
