
## 目标
参考 QEMU(https://github.com/qemu/qemu) 的实现，采用动态虚拟化技术，通过堆模拟寄存器和 CPU 状态，实现动态执行ARM64汇编代码。

## Prompt 历史记录


为了能够对标 QEMU(https://github.com/qemu/qemu)，我需要对目前程序的结构做好规划，以便后面扩展做准备。

模块化架构优势
组件解耦: 每个模块有明确职责，便于维护和测试
扩展性: 新增指令、设备或功能时只需扩展对应模块
代码复用: 通用功能可以在各模块间共享
更接近QEMU架构: 为后续增强功能提供稳固基础
