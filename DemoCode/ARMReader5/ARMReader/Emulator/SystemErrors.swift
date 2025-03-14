//
//  SystemErrors.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

/// 定义模拟器可能遇到的错误
enum EmulatorError: Error {
    /// 内存访问越界
    case memoryAccessOutOfBounds(address: UInt64)

    /// 程序计数器越界或不对齐
    case programCounterOutOfBounds(address: UInt64)

    /// 不支持的指令
    case unsupportedInstruction(UInt8)

    /// 不支持的指令格式
    case unsupportedInstructionFormat(format: String, opcode: UInt8, details: String)

    /// 设备错误
    case deviceError(message: String)

    /// 未实现的功能
    case notImplemented(String)
}

extension EmulatorError: CustomStringConvertible {
    var description: String {
        switch self {
        case .memoryAccessOutOfBounds(let address):
            return "内存访问越界: 0x\(String(format: "%016X", address))"

        case .programCounterOutOfBounds(let address):
            return "程序计数器越界或未对齐: 0x\(String(format: "%016X", address))"

        case .unsupportedInstruction(let opcode):
            return "不支持的指令: 0x\(String(format: "%02X", opcode))"

        case .unsupportedInstructionFormat(let format, let opcode, let details):
            return "不支持的指令格式: \(format), 操作码: 0x\(String(format: "%02X", opcode)), 详情: \(details)"

        case .deviceError(let message):
            return "设备错误: \(message)"

        case .notImplemented(let feature):
            return "未实现的功能: \(feature)"
        }
    }
}

extension EmulatorError: LocalizedError {
    var errorDescription: String? {
        return description
    }
}

