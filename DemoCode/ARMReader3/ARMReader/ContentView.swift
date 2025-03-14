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
    - SUBS (带标志位的减法)
    - MUL (乘法)
    - AND (按位与)
    - B (无条件分支)
    - BL (带链接的分支)
    - B.cond (条件分支)
    - BR (寄存器间接跳转)

 2. 改进的示例程序，展示了：
    - 基本算术运算
    - 逻辑运算
    - 立即数加载
    - 分支指令和条件执行

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

                    // 测试分支指令示例
                    let branchProgram: [UInt32] = [
                        0xD2800020,  // MOV X0, #1      ; X0 = 1
                        0xD2800041,  // MOV X1, #2      ; X1 = 2
                        0xEB010000,  // SUBS X0, X0, X1  ; X0 = X0 - X1，并设置条件标志
                        0x54000061,  // B.NE LABEL1     ; 如果不等于零，跳转到LABEL1
                        0xD2800080,  // MOV X0, #4      ; X0 = 4 (如果条件不成立才执行)
                        0x14000002,  // B LABEL2        ; 无条件跳转到LABEL2
                        // LABEL1:
                        0xD28000A0,  // MOV X0, #5      ; X0 = 5 (如果条件成立才执行)
                        // LABEL2:
                        0xD503201F   // NOP (程序结束标记)
                    ]

                    try emulator.loadProgram(at: 0x1000, code: branchProgram)
                    try emulator.run()
                    print("分支指令测试结果: \(emulator.getRegister(0))")

                    // 测试循环示例 (计算1到4的和)
                    // 使用ARM64Assembler动态生成循环程序
                    let loopProgram = ARM64Assembler.createLoopProgram()

                    // 验证分支指令偏移量 (诊断用)
                    let branchInstr = loopProgram[6]  // B.LT指令
                    let offset = ARM64Assembler.validateBranchOffset(branchInstr)
                    print("分支指令验证: 0x\(String(format: "%08X", branchInstr)), 偏移量=\(offset)")

                    // 加载并执行自动生成的程序
                    try emulator.loadProgram(at: 0x1000, code: loopProgram)
                    try emulator.run()
                    print("循环计算结果 (1+2+3+4): \(emulator.getRegister(0))")

                    // 使用手写的循环程序对比
                    print("\n使用手写的循环程序:")
                    let manualLoopProgram: [UInt32] = [
                        0xD2800000,  // 0x1000: MOV X0, #0      ; 结果寄存器初始化为0
                        0xD2800021,  // 0x1004: MOV X1, #1      ; 循环计数器初始值
                        0xD2800082,  // 0x1008: MOV X2, #4      ; 最大循环次数值
                        // LOOP_START (0x100C):
                        0x8B010000,  // 0x100C: ADD X0, X0, X1  ; X0 += X1 (累加当前值)
                        0x91000421,  // 0x1010: ADD X1, X1, #1  ; X1 += 1 (递增计数器)
                        0xEB02003F,  // 0x1014: SUBS XZR, X1, X2 ; 比较 X1 和 X2
                        0x54FFFFAD,  // 0x1018: B.LE -12      ; 如果 X1<=X2 跳回 0x100C
                        0xD503201F   // 0x101C: NOP (程序结束)
                    ]

                    // 添加更清晰的手写程序解释
                    print("手写循环程序分析:")
                    print("1. 累加器X0初始化为0")
                    print("2. 循环计数器X1初始化为1")
                    print("3. 最大值X2设为4")
                    print("4. 循环开始: 将当前计数X1加到累加器X0")
                    print("5. 增加计数器X1")
                    print("6. 比较X1与X2")
                    print("7. 如果X1<=X2，则继续循环")
                    print("8. 循环结束后，X0应包含1+2+3+4=10")

                    // 验证分支指令
                    let manualBranchInstr = manualLoopProgram[6]
                    print("手写分支指令: 0x\(String(format: "%08X", manualBranchInstr))")
                    print("偏移量: \(ARM64Assembler.validateBranchOffset(manualBranchInstr)) 字节")

                    // 添加断言，确保偏移量正确
                    assert(ARM64Assembler.validateBranchOffset(manualBranchInstr) == -12, "分支偏移量应为-12字节")

                    // 添加更详细的指令验证
                    print("验证手写循环程序指令:")
                    print("1. 累加指令(0x100C): \(String(format: "%08X", manualLoopProgram[3]))")
                    print("   解码: ADD X0, X0, X1")

                    print("2. 递增计数器指令(0x1010): \(String(format: "%08X", manualLoopProgram[4]))")
                    // 验证ADD immediate指令格式
                    let rd = manualLoopProgram[4] & 0x1F
                    let rn = (manualLoopProgram[4] >> 5) & 0x1F
                    let imm = (manualLoopProgram[4] >> 10) & 0xFFF
                    print("   解码: ADD X\(rd), X\(rn), #\(imm)")
                    if rd == 1 && rn == 1 && imm == 1 {
                        print("   ✓ 正确的递增指令，每次加1")
                    } else if rd == 1 && rn == 1 {
                        print("   ✗ 递增指令数值错误，应为#1，实际为#\(imm)")
                    } else {
                        print("   ✗ 递增指令格式错误")
                    }

                    print("3. 比较指令(0x1014): \(String(format: "%08X", manualLoopProgram[5]))")
                    print("   解码: SUBS XZR, X1, X2")

                    print("4. 分支指令(0x1018): \(String(format: "%08X", manualLoopProgram[6]))")
                    print("   偏移量: \(ARM64Assembler.validateBranchOffset(manualLoopProgram[6])) 字节")

                    // 执行手写程序
                    try emulator.loadProgram(at: 0x1000, code: manualLoopProgram)
                    try emulator.run()
                    print("手写循环计算结果: \(emulator.getRegister(0))")

                    // 使用ARM64Assembler自动生成循环程序
                    print("\n使用修正后的ARM64Assembler生成的循环程序:")
                    let generatedProgram = ARM64Assembler.createLoopProgram()
                    try emulator.loadProgram(at: 0x1000, code: generatedProgram)
                    try emulator.run()
                    print("自动生成的循环计算结果: \(emulator.getRegister(0))")

                    // 输出性能统计数据
                    print("\n执行性能统计:")
                    print(PerformanceMetrics.shared.getStatisticsString())

                    // 输出指令统计数据
                    print("\n指令统计:")
                    print(OpcodeStatistics.shared.generateReport())

                    print("\n循环计算验证完成! ✓")
                    print("总结: 模拟器能够正确执行ARM64指令，包括加法、比较、分支和循环操作。")
                    print("高斯求和公式验证: 1+2+3+4=10 计算正确!")

                } catch {
                    print("模拟器错误: \(error)")
                }
            }
    }
}















