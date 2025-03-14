//
//  SIMDRegister.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/16.
//

import Foundation

/// 定义可以存储在SIMD寄存器中的元素类型
protocol SIMDElement {
    static var byteSize: Int { get }
    init()
    init(_ value: UInt64)
    func toUInt64() -> UInt64
}

// SIMD元素类型实现
extension UInt8: SIMDElement {
    static var byteSize: Int { return 1 }
    init(_ value: UInt64) { self = UInt8(truncatingIfNeeded: value) }
    func toUInt64() -> UInt64 { return UInt64(self) }
}

extension UInt16: SIMDElement {
    static var byteSize: Int { return 2 }
    init(_ value: UInt64) { self = UInt16(truncatingIfNeeded: value) }
    func toUInt64() -> UInt64 { return UInt64(self) }
}

extension UInt32: SIMDElement {
    static var byteSize: Int { return 4 }
    init(_ value: UInt64) { self = UInt32(truncatingIfNeeded: value) }
    func toUInt64() -> UInt64 { return UInt64(self) }
}

extension UInt64: SIMDElement {
    static var byteSize: Int { return 8 }
    init(_ value: UInt64) { self = value }
    func toUInt64() -> UInt64 { return self }
}

extension Int8: SIMDElement {
    static var byteSize: Int { return 1 }
    init(_ value: UInt64) { self = Int8(truncatingIfNeeded: Int(value)) }
    func toUInt64() -> UInt64 { return UInt64(bitPattern: Int64(self)) }
}

extension Int16: SIMDElement {
    static var byteSize: Int { return 2 }
    init(_ value: UInt64) { self = Int16(truncatingIfNeeded: Int(value)) }
    func toUInt64() -> UInt64 { return UInt64(bitPattern: Int64(self)) }
}

extension Int32: SIMDElement {
    static var byteSize: Int { return 4 }
    init(_ value: UInt64) { self = Int32(truncatingIfNeeded: Int(value)) }
    func toUInt64() -> UInt64 { return UInt64(bitPattern: Int64(self)) }
}

extension Int64: SIMDElement {
    static var byteSize: Int { return 8 }
    init(_ value: UInt64) { self = Int64(bitPattern: value) }
    func toUInt64() -> UInt64 { return UInt64(bitPattern: self) }
}

// 浮点类型（使用位模式转换）
extension Float: SIMDElement {
    static var byteSize: Int { return 4 }

    init(_ value: UInt64) {
        let uint32Value = UInt32(truncatingIfNeeded: value)
        self = Float(bitPattern: uint32Value)
    }

    func toUInt64() -> UInt64 {
        return UInt64(self.bitPattern)
    }
}

extension Double: SIMDElement {
    static var byteSize: Int { return 8 }

    init(_ value: UInt64) {
        self = Double(bitPattern: value)
    }

    func toUInt64() -> UInt64 {
        return self.bitPattern
    }
}

/// SIMD寄存器类型 - 128位寄存器(16字节)
struct SIMDRegister {
    // 使用16个字节存储，支持不同的SIMD元素大小
    private var bytes: [UInt8] = Array(repeating: 0, count: 16)

    // 创建一个空的SIMD寄存器
    init() {}

    // 通过UInt64值初始化（设置低位和高位）
    init(low: UInt64, high: UInt64 = 0) {
        setUInt64(0, value: low)
        setUInt64(8, value: high)
    }

    // 通过字节数组初始化
    init(bytes: [UInt8]) {
        precondition(bytes.count <= 16, "SIMD寄存器最多支持16字节")
        for i in 0..<min(bytes.count, 16) {
            self.bytes[i] = bytes[i]
        }
    }

    // 获取字节视图
    var rawBytes: [UInt8] {
        return bytes
    }

    // 获取特定位置的字节
    func getByte(at index: Int) -> UInt8 {
        guard index >= 0 && index < 16 else { return 0 }
        return bytes[index]
    }

    // 设置特定位置的字节
    mutating func setByte(_ index: Int, value: UInt8) {
        guard index >= 0 && index < 16 else { return }
        bytes[index] = value
    }

    // 获取UInt64形式的低64位/高64位
    func getLowerUInt64() -> UInt64 {
        return getUInt64(0)
    }

    func getUpperUInt64() -> UInt64 {
        return getUInt64(8)
    }

    // 辅助函数：从特定字节偏移获取UInt64
    private func getUInt64(_ byteOffset: Int) -> UInt64 {
        guard byteOffset >= 0 && byteOffset <= 8 else { return 0 }
        var value: UInt64 = 0
        for i in 0..<8 {
            if byteOffset + i < 16 {
                value |= UInt64(bytes[byteOffset + i]) << (i * 8)
            }
        }
        return value
    }

    // 辅助函数：设置特定字节偏移的UInt64
    private mutating func setUInt64(_ byteOffset: Int, value: UInt64) {
        guard byteOffset >= 0 && byteOffset <= 8 else { return }
        for i in 0..<8 {
            if byteOffset + i < 16 {
                bytes[byteOffset + i] = UInt8((value >> (i * 8)) & 0xFF)
            }
        }
    }

    // 获取特定通道的元素
    func getElement<T: SIMDElement>(lane: Int, as type: T.Type) -> T {
        let byteSize = T.byteSize
        let maxLanes = 16 / byteSize

        guard lane >= 0 && lane < maxLanes else { return T() }
        let byteOffset = lane * byteSize

        var value: UInt64 = 0
        for i in 0..<byteSize {
            if byteOffset + i < 16 {
                value |= UInt64(bytes[byteOffset + i]) << (i * 8)
            }
        }

        return T(value)
    }

    // 设置特定通道的元素
    mutating func setElement<T: SIMDElement>(lane: Int, value: T) {
        let byteSize = T.byteSize
        let maxLanes = 16 / byteSize

        guard lane >= 0 && lane < maxLanes else { return }
        let byteOffset = lane * byteSize

        let rawValue = value.toUInt64()
        for i in 0..<byteSize {
            if byteOffset + i < 16 {
                bytes[byteOffset + i] = UInt8((rawValue >> (i * 8)) & 0xFF)
            }
        }
    }

    // 获取所有元素组成的数组
    func getAllElements<T: SIMDElement>(as type: T.Type) -> [T] {
        let byteSize = T.byteSize
        let count = 16 / byteSize

        var elements = [T]()
        for i in 0..<count {
            elements.append(getElement(lane: i, as: type))
        }

        return elements
    }
}
