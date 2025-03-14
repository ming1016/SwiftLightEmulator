//
//  ContentView.swift
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

import SwiftUI

/*
 功能：

 1. 新增指令支持：
    - MOV (移动立即数到寄存器)
    - SUB (减法)
    - MUL (乘法)
    - AND (按位与)

 2. 改进的示例程序，展示了：
    - 基本算术运算
    - 逻辑运算
    - 立即数加载

 3. 更好的指令解码结构：
    - 使用 switch 语句进行指令分类
    - 更详细的操作码解析
    - 支持立即数操作

 4. 模块化设计规划 (QEMU 风格):
    - CPU 核心模拟 (ARM64CPU)
    - 内存管理与映射
    - 指令解码与执行管道
    - 设备模拟框架
    - 总线系统
 */


import SwiftUI
import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ContentView: View {
    var body: some View {
        Text("计算结果将在控制台显示")
            .padding()
            .onAppear {
                do {
                    let emulator = LightEmulator()

                    // 示例程序：演示多个指令操作
                    let program: [UInt32] = [
                        0xD2800140,  // MOV X0, #10     ; X0 = 10
                        0xD2800061,  // MOV X1, #3      ; X1 = 3
                        0x8B010000,  // ADD X0, X0, X1  ; X0 = X0 + X1
                        0xCB010000,  // SUB X0, X0, X1  ; X0 = X0 - X1
                        0x9B017C00,  // MUL X0, X0, X1  ; X0 = X0 * X1
                        0xD503201F   // NOP (程序结束标记)
                    ]
                    try emulator.loadProgram(at: 0x1000, code: program)
                    try emulator.run()

                    // 打印结果
                    print("计算结果: \(emulator.getRegister(0))")

                    // 测试逻辑运算示例
                    let logicProgram: [UInt32] = [
                        0xD2800140,  // MOV X0, #10
                        0xD2800061,  // MOV X1, #3
                        0x8A010000,  // AND X0, X0, X1
                        0xD503201F   // NOP
                    ]

                    try emulator.loadProgram(at: 0x1000, code: logicProgram)
                    try emulator.run()
                    print("逻辑运算结果: \(emulator.getRegister(0))")

                } catch {
                    print("模拟器错误: \(error)")
                }
            }
    }
}















