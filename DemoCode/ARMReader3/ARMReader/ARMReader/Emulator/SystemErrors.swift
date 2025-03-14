//
//  SystemErrors.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

// 模拟器相关错误定义
enum EmulatorError: Error, CustomStringConvertible {
    case unsupportedInstruction(UInt8)
    case unsupportedInstructionFormat(format: String, opcode: UInt8, details: String)
    case memoryAccessOutOfBounds(address: UInt64)
    case programCounterOutOfBounds(address: UInt64)
    case deviceError(message: String)

    var description: String {
        switch self {
        case .unsupportedInstruction(let opcode):
            return "不支持的指令操作码: 0x\(String(format: "%02X", opcode))"
        case .unsupportedInstructionFormat(let format, let opcode, let details):
            return "不支持的指令格式 \(format) (操作码: 0x\(String(format: "%02X", opcode))): \(details)"
        case .memoryAccessOutOfBounds(let address):
            return "内存访问越界: 0x\(String(format: "%016X", address))"
        case .programCounterOutOfBounds(let address):
            return "程序计数器越界: 0x\(String(format: "%016X", address))"
        case .deviceError(let message):
            return "设备错误: \(message)"
        }
    }
}

