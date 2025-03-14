//
//  MemoryManager.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//
import Foundation

// 内存管理器 - 处理内存访问与映射
class MemoryManager {
    private var memory: [UInt8]
    private var memoryMap: [MemoryRegion] = []

    struct MemoryRegion {
        let start: UInt64
        let size: UInt64
        let isReadOnly: Bool
        let name: String
    }

    init(size: UInt64) {
        memory = Array(repeating: 0, count: Int(size))
        // 创建默认内存映射
        memoryMap.append(MemoryRegion(start: 0, size: size, isReadOnly: false, name: "RAM"))
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

    // 添加内存区域映射
    func addMemoryRegion(start: UInt64, size: UInt64, isReadOnly: Bool, name: String) {
        memoryMap.append(MemoryRegion(start: start, size: size, isReadOnly: isReadOnly, name: name))
    }

    // 检查地址是否有效
    func isValidAddress(_ address: UInt64) -> Bool {
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
