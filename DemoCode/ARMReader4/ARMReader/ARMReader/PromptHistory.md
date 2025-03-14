## 目标
参考 QEMU(https://github.com/qemu/qemu) 的实现，采用动态虚拟化技术，通过堆模拟寄存器和 CPU 状态，实现动态执行ARM64汇编代码。

## 模版提示词
- [使用 Chat @workspace]我打算一步一步完善这个模拟器，对标QEMU(https://github.com/qemu/qemu)，这次我想按照QEMU的方式完成{XX}功能。请帮我写一个提示词，指导我如何实现这个功能，列出涉及需要修改的文件。
- [使用 Composer]ARM64模拟器实现{XX}功能，按照QEMU(https://github.com/qemu/qemu)相应功能实现的方式，并提供示例进行验证。
    - XX.swift
    - XX2.swift
    - ...

## Prompt 历史记录
我打算一步一步完善这个模拟器，对标QEMU(https://github.com/qemu/qemu)，这次我想按照QEMU的方式完成实现更多数据处理指令。请帮我写一个提示词，指导我如何实现，列出涉及需要修改的文件。

ARM64模拟器实现更多数据处理指令，按照QEMU(https://github.com/qemu/qemu)相应功能实现的方式，并提供示例进行验证。
Emulator/InstructionDecoder.swift
Emulator/ARM64CPU.swift
Emulator/Tests/DataProcessingInstructionTests.swift
Emulator/ARM64Assembler.swift
Emulator/Debugger.swift
Emulator/EmulatorDebugTools.swift


ARM64模拟器实现分支指令和条件执行功能，并提供示例进行验证。

我打算一步一步完善这个模拟器，现在我想先完成分支指令支持，并且添加条件执行功能，并提供示例进行验证。请帮我写一个提示词，指导我如何实现这两个功能。

帮我写个提示词，我打算和QEMU(https://github.com/qemu/qemu)对标，实现一个ARM64的模拟器。现在工作区是一个最简单的原型版本，但是需要编写的代码会很多，因此我需要你帮我写下一个有合理顺序的步骤，要求完整，可以不用具体，这样我就可以按照你的提示词，一步一步的实现这个模拟器。

为了能够对标 QEMU(https://github.com/qemu/qemu)，我需要对目前程序的结构做好规划，以便后面扩展做准备。是一个最简单的原型版本，但是需要编写的代码会很多，因此我需要你帮我写下一个有合理顺序的步骤，要求完整，可以不用具体，这样我就可以按照你的提示词，一步一步的实现这个模拟器。

模块化架构优势QEMU(https://github.com/qemu/qemu)，我需要对目前程序的结构做好规划，以便后面扩展做准备。
组件解耦: 每个模块有明确职责，便于维护和测试
扩展性: 新增指令、设备或功能时只需扩展对应模块
代码复用: 通用功能可以在各模块间共享护和测试
更接近QEMU架构: 为后续增强功能提供稳固基础
代码复用: 通用功能可以在各模块间共享




