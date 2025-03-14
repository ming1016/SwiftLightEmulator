//
//  DeviceInterface.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import Foundation

// 设备控制器接口
protocol DeviceController {
    var size: UInt64 { get }
    func read(at offset: UInt64) throws -> UInt64
    func write(at offset: UInt64, value: UInt64) throws
}

// 设备管理器
class DeviceManager {
    private var devices: [String: DeviceController] = [:]

    func registerDevice(_ name: String, device: DeviceController) {
        devices[name] = device
    }

    func getDevice(_ name: String) -> DeviceController? {
        return devices[name]
    }
}
