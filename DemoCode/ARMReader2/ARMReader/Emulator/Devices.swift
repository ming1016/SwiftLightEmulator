//
//  Device.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//


// 设备接口
protocol Device {
    var size: UInt64 { get }

    func read(at offset: UInt64, size: Int) -> [UInt8]
    func write(at offset: UInt64, data: [UInt8])
}

// 设备管理器
class DeviceManager {
    private var devices: [Device] = []

    func addDevice(_ device: Device) {
        devices.append(device)
    }

    func getDevices() -> [Device] {
        return devices
    }
}