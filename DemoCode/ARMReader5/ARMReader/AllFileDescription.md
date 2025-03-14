//
//  AllFileDescription.md
//  ARMReader
//
//  Created by Ming Dai on 2025/3/14.
//

提示词：
```
Emulator目前有的能力，将能力的描述同步更新到AllFileDescription.md文件中。
```

ARMReader是一个模拟ARM64架构的轻量级模拟器项目，其架构借鉴了QEMU的设计理念。根据工作区中的文件，我可以对项目结构和功能进行分析。

## 项目结构

ARMReader是一个多平台应用（支持iOS、macOS和visionOS），采用SwiftUI构建界面，主要由以下组件组成：

- 主应用程序：ARMReaderApp.swift和ContentView.swift
- 模拟器核心：位于Emulator目录下

## 模拟器核心组件

1. **LightEmulator.swift** - 模拟器的主要实现，整合其他组件
2. **ARM64CPU.swift** - CPU实现，管理寄存器和执行指令
3. **MemoryManager.swift** - 内存管理实现
4. **InstructionDecoder.swift** - 指令解码器
5. **SystemBus.swift** - 系统总线，连接CPU、内存和设备
6. **Devices.swift** - 设备模拟框架
7. **Debugger.swift** - 调试工具和错误处理

## 当前功能

模拟器目前支持的ARM64指令：
- 基本算术运算：ADD, SUB
- 乘法操作：MUL
- 逻辑运算：AND
- 数据移动：MOV（立即数）
- 系统指令：NOP

## 架构特点

1. **模块化设计**：各组件职责明确，便于维护和扩展
2. **QEMU风格架构**：
   - 通过总线连接各组件
   - 设备可注册到系统
   - 内存区域可映射
3. **错误处理**：完善的错误类型和描述

## 运行示例

在ContentView.swift中可以看到示例程序，展示了：
- 基本算术运算
- 逻辑运算
- 立即数加载

执行流程是：
1. 创建模拟器实例
2. 加载示例程序到内存
3. 运行程序直到遇到NOP指令
4. 打印计算结果
