import Foundation

/// 浮点指令执行器 - 负责执行所有浮点运算指令
class FloatingPointExecutor {
    // 浮点指令主分类
    enum FPInstructionType {
        case fpAdd              // 浮点加法
        case fpSub              // 测点减法
        case fpMul              // 浮点乘法
        case fpDiv              // 浮点除法
        case fpSqrt             // 浮点平方根
        case fpAbs              // 浮点绝对值
        case fpNeg              // 浮点取负
        case fpMin              // 浮点最小值
        case fpMax              // 浮点最大值
        case fpCmp              // 浮点比较
        case fpCvt              // 浮点格式转换
        case fpLoad             // 浮点加载
        case fpStore            // 浮点存储
        case fpMove             // 寄存器移动
        case intToFP            // 整数到浮点转换
        case fpToInt            // 浮点到整数转换
        case unknown            // 未知/不支持
    }

    // 精度类型
    enum Precision {
        case single     // 32位单精度
        case double     // 64位双精度
    }

    // 浮点舍入模式
    enum RoundingMode {
        case nearest    // 就近舍入
        case zero       // 向零舍入
        case plus       // 向正无穷舍入
        case minus      // 向负无穷舍入
    }

    // 指令执行环境
    private let cpu: ARM64CPU
    private let memory: MemoryManager?

    init(cpu: ARM64CPU, memory: MemoryManager? = nil) {
        self.cpu = cpu
        self.memory = memory
    }

    /// 执行浮点指令
    func execute(_ instruction: UInt32) throws {
        // 解码指令主类别
        let type = decodeInstructionType(instruction)
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("浮点指令类型: \(type)")
        }

        // 根据指令类型分发到具体处理函数
        switch type {
        case .fpAdd:
            try executeFPAdd(instruction)
        case .fpSub:
            try executeFPSub(instruction)
        case .fpMul:
            try executeFPMul(instruction)
        case .fpDiv:
            try executeFPDiv(instruction)
        case .fpLoad:
            try executeFPLoad(instruction)
        case .fpStore:
            try executeFPStore(instruction)
        case .fpCvt:
            try executeFPCvt(instruction)
        case .fpMove:
            try executeFPMove(instruction)
        case .intToFP:
            try executeIntToFP(instruction)
        case .fpToInt:
            try executeFPToInt(instruction)
        case .fpCmp:
            try executeFPCmp(instruction)
        default:
            throw EmulatorError.unsupportedInstructionFormat(
                format: "0x\(String(format: "%08X", instruction))",
                opcode: UInt8((instruction >> 24) & 0xFF),
                details: "不支持的浮点指令类型: \(type)"
            )
        }
    }

    /// 解码浮点指令类型
    private func decodeInstructionType(_ instruction: UInt32) -> FPInstructionType {
        let opcode = (instruction >> 24) & 0xFF
        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("  浮点指令解码: 0x\(String(format: "%08X", instruction)), 操作码: 0x\(String(format: "%02X", opcode))")
        }

        // 先进行精确匹配 - 解决识别问题
        if instruction == 0x1E270020 || instruction == 0x1E270021 {
            if debugMode {
                print("  精确匹配: 位模式移动指令 0x\(String(format: "%08X", instruction))")
            }
            return .intToFP
        }

        // 添加对特定指令的精确匹配
        if (instruction & 0xFFE0FC00) == 0x1E210800 {
            if debugMode {
                print("  精确匹配: 浮点乘法指令")
            }
            return .fpMul
        }

        if (instruction & 0xFFE0FC00) == 0x1E211800 {
            if debugMode {
                print("  精确匹配: 浮点除法指令")
            }
            return .fpDiv
        }

        // 改进的指令识别逻辑
        if opcode == 0x1E || opcode == 0x1F || opcode == 0x9E {
            // 提取更精细的操作码字段
            let op = (instruction >> 20) & 0x1F
            let rmode = (instruction >> 19) & 0x3
            let opcode2 = (instruction >> 10) & 0x3F
            let topBits = (instruction >> 28) & 0xF

            if debugMode {
                print("  扩展指令分析: op=\(op), rmode=\(rmode), opcode2=\(opcode2), topBits=\(topBits)")

                // 添加更详细的指令模式分析
                let instructionPattern = instruction & 0xFFE0FC00
                print("  指令模式: 0x\(String(format: "%08X", instructionPattern))")

                // 检查特定的指令模式
                if (instructionPattern == 0x1E200800) {
                    print("  符合乘法指令模式")
                } else if (instructionPattern == 0x1E201800) {
                    print("  符合除法指令模式")
                }
            }

            // 检查新增的位模式移动指令 - 改进匹配规则
            if ((instruction & 0xFFE00000) == 0x1E200000) && ((instruction & 0x0000FC00) == 0x00000000) {
                // 指令的基本模式是1E2xxxxx且低位部分为0
                let specificOp = (instruction >> 16) & 0xF
                if specificOp == 0x7 {
                    if debugMode {
                        print("  识别为整数到浮点的位模式移动指令")
                    }
                    return .intToFP
                }
            }

            // 检查明确的浮点操作类型
            // 检查明确的乘法模式
            if ((instruction & 0xFFE0FC00) == 0x1E200800) {
                if debugMode {
                    print("  明确识别为浮点乘法")
                }
                return .fpMul
            }

            // 检查明确的除法模式
            if ((instruction & 0xFFE0FC00) == 0x1E201800) {
                if debugMode {
                    print("  明确识别为浮点除法")
                }
                return .fpDiv
            }

            // 专门检查浮点到整数转换指令
            if (instruction & 0xFFBF0000) == 0x1E380000 {
                // 这是正确的FCVTZS/FCVTZU指令模式
                if debugMode {
                    print("  识别为浮点到整数转换指令 (FCVTZS/FCVTZU)")
                }
                return .fpToInt
            }

            // 检查整数到浮点转换指令
            if (instruction & 0xFFBF0000) == 0x1E220000 {
                if debugMode {
                    print("  识别为整数到浮点转换指令 (SCVTF/UCVTF)")
                }
                return .intToFP
            }

            // 检查FMOV指令
            if (instruction & 0xFFE0FC00) == 0x1E204000 {
                // 这是FMOV指令
                return .fpMove
            }

            // 浮点指令类型识别 - 基于操作码
            switch op {
            case 0x00:
                if debugMode { print("  基于操作码识别: 浮点乘法") }
                return .fpMul
            case 0x01:
                if debugMode { print("  基于操作码识别: 浮点除法") }
                return .fpDiv
            case 0x02: return .fpAdd
            case 0x03: return .fpSub
            case 0x04: return .fpMax
            case 0x05: return .fpMin
            case 0x06: return .fpCmp
            default:
                // 未识别的浮点操作码，尝试匹配特殊指令
                break
            }
        }

        // 直接匹配位模式
        if instruction == 0x1E270020 || instruction == 0x1E270021 {
            if debugMode {
                print("  直接匹配: 位模式移动指令")
            }
            return .intToFP
        }

        return .unknown
    }

    /// 获取指令的精度
    private func getPrecision(_ instruction: UInt32) -> Precision {
        // 根据指令中的编码确定精度
        let type = (instruction >> 22) & 0x3
        // 浮点指令通常使用bit 22来区分单/双精度
        return (type & 0x1) == 0 ? .single : .double
    }

    // MARK: - 基本浮点运算指令实现

    /// 执行浮点加法指令 (FADD)
    private func executeFPAdd(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        // 修正: 从指令中正确提取rm寄存器，使用位16-20
        let rm = Int((instruction >> 16) & 0x1F)
        let precision = getPrecision(instruction)

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled
        if debugMode {
            print("  执行浮点加法: rd=\(rd), rn=\(rn), rm=\(rm)")
            print("  操作码解析: 0x\(String(format: "%08X", instruction))")
            print("  寄存器字段: rd=0x\(String(format: "%X", rd)), rn=0x\(String(format: "%X", rn)), rm=0x\(String(format: "%X", rm))")

            // 打印详细的二进制解析，帮助验证寄存器字段提取
            print("  指令二进制: \(String(instruction, radix: 2).padding(toLength: 32, withPad: "0", startingAt: 0))")
            print("  rd字段(0-4): \(String(instruction & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rd))")
            print("  rn字段(5-9): \(String((instruction >> 5) & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rn))")
            print("  rm字段(16-20): \(String((instruction >> 16) & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rm))")

            // 添加额外的调试信息，打印寄存器的实际值
            print("  寄存器值: S\(rn)=\(cpu.getFloatRegister(UInt32(rn))), S\(rm)=\(cpu.getFloatRegister(UInt32(rm)))")
        }

        switch precision {
        case .single:
            let a = cpu.getFloatRegister(UInt32(rn))
            let b = cpu.getFloatRegister(UInt32(rm))
            let result = a + b
            cpu.setFloatRegister(UInt32(rd), value: result)

            if debugMode {
                print("  FADD S\(rd), S\(rn), S\(rm): \(a) + \(b) = \(result)")
            }

        case .double:
            let a = cpu.getDoubleRegister(UInt32(rn))
            let b = cpu.getDoubleRegister(UInt32(rm))
            let result = a + b
            cpu.setDoubleRegister(UInt32(rd), value: result)

            if EmulatorDebugTools.shared.isDebugModeEnabled {
                print("  FADD D\(rd), D\(rn), D\(rm): \(a) + \(b) = \(result)")
            }
        }
    }

    /// 执行浮点减法指令 (FSUB)
    private func executeFPSub(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        // 修正: 从指令中正确提取rm寄存器，使用位16-20
        let rm = Int((instruction >> 16) & 0x1F)
        let precision = getPrecision(instruction)

        switch precision {
        case .single:
            let a = cpu.getFloatRegister(UInt32(rn))
            let b = cpu.getFloatRegister(UInt32(rm))
            let result = a - b
            cpu.setFloatRegister(UInt32(rd), value: result)

            if EmulatorDebugTools.shared.isDebugModeEnabled {
                print("  FSUB S\(rd), S\(rn), S\(rm): \(a) - \(b) = \(result)")
            }

        case .double:
            let a = cpu.getDoubleRegister(UInt32(rn))
            let b = cpu.getDoubleRegister(UInt32(rm))
            let result = a - b
            cpu.setDoubleRegister(UInt32(rd), value: result)

            if EmulatorDebugTools.shared.isDebugModeEnabled {
                print("  FSUB D\(rd), D\(rn), D\(rm): \(a) - \(b) = \(result)")
            }
        }
    }

    /// 执行浮点乘法指令 (FMUL)
    private func executeFPMul(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let precision = getPrecision(instruction)

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled
        if debugMode {
            print("  执行浮点乘法: rd=\(rd), rn=\(rn), rm=\(rm)")
            print("  指令: 0x\(String(format: "%08X", instruction))")
            // 详细验证寄存器字段
            print("  寄存器字段: rd=0x\(String(format: "%X", rd)), rn=0x\(String(format: "%X", rn)), rm=0x\(String(format: "%X", rm))")
            print("  指令二进制: \(String(instruction, radix: 2).padding(toLength: 32, withPad: "0", startingAt: 0))")
            print("  rd字段(0-4): \(String(instruction & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rd))")
            print("  rn字段(5-9): \(String((instruction >> 5) & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rn))")
            print("  rm字段(16-20): \(String((instruction >> 16) & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rm))")
            // 添加额外的调试信息，打印寄存器的实际值
            print("  寄存器值: S\(rn)=\(cpu.getFloatRegister(UInt32(rn))), S\(rm)=\(cpu.getFloatRegister(UInt32(rm)))")
        }

        switch precision {
        case .single:
            let a = cpu.getFloatRegister(UInt32(rn))
            let b = cpu.getFloatRegister(UInt32(rm))
            let result = a * b
            cpu.setFloatRegister(UInt32(rd), value: result)

            if debugMode {
                print("  FMUL S\(rd), S\(rn), S\(rm): \(a) * \(b) = \(result)")
            }
        case .double:
            let a = cpu.getDoubleRegister(UInt32(rn))
            let b = cpu.getDoubleRegister(UInt32(rm))
            let result = a * b
            cpu.setDoubleRegister(UInt32(rd), value: result)

            if EmulatorDebugTools.shared.isDebugModeEnabled {
                print("  FMUL D\(rd), D\(rn), D\(rm): \(a) * \(b) = \(result)")
            }
        }
    }

    /// 执行浮点除法指令 (FDIV)
    private func executeFPDiv(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let precision = getPrecision(instruction)

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled
        if debugMode {
            print("  执行浮点除法: rd=\(rd), rn=\(rn), rm=\(rm)")
            print("  指令: 0x\(String(format: "%08X", instruction))")
            // 详细验证寄存器字段
            print("  寄存器字段: rd=0x\(String(format: "%X", rd)), rn=0x\(String(format: "%X", rn)), rm=0x\(String(format: "%X", rm))")
            print("  指令二进制: \(String(instruction, radix: 2).padding(toLength: 32, withPad: "0", startingAt: 0))")
            print("  rd字段(0-4): \(String(instruction & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rd))")
            print("  rn字段(5-9): \(String((instruction >> 5) & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rn))")
            print("  rm字段(16-20): \(String((instruction >> 16) & 0x1F, radix: 2).padding(toLength: 5, withPad: "0", startingAt: 0)) (\(rm))")
            // 添加额外的调试信息，打印寄存器的实际值
            print("  寄存器值: S\(rn)=\(cpu.getFloatRegister(UInt32(rn))), S\(rm)=\(cpu.getFloatRegister(UInt32(rm)))")
        }

        switch precision {
        case .single:
            let a = cpu.getFloatRegister(UInt32(rn))
            let b = cpu.getFloatRegister(UInt32(rm))

            // 检查除零
            if b == 0 {
                // 处理除零情况
                cpu.setFloatRegister(UInt32(rd), value: Float.infinity * (a < 0 ? -1.0 : 1.0))
                // 设置除零标志
                cpu.setFPSR(cpu.getFPSR() | 0x01)

                if EmulatorDebugTools.shared.isDebugModeEnabled {
                    print("  FDIV S\(rd), S\(rn), S\(rm): \(a) / \(b) = 除零错误")
                }
            } else {
                let result = a / b
                cpu.setFloatRegister(UInt32(rd), value: result)

                if EmulatorDebugTools.shared.isDebugModeEnabled {
                    print("  FDIV S\(rd), S\(rn), S\(rm): \(a) / \(b) = \(result)")
                }
            }

        case .double:
            let a = cpu.getDoubleRegister(UInt32(rn))
            let b = cpu.getDoubleRegister(UInt32(rm))

            // 检查除零
            if b == 0 {
                // 处理除零情况
                cpu.setDoubleRegister(UInt32(rd), value: Double.infinity * (a < 0 ? -1.0 : 1.0))
                // 设置除零标志
                cpu.setFPSR(cpu.getFPSR() | 0x01)

                if EmulatorDebugTools.shared.isDebugModeEnabled {
                    print("  FDIV D\(rd), D\(rn), D\(rm): \(a) / \(b) = 除零错误")
                }
            } else {
                let result = a / b
                cpu.setDoubleRegister(UInt32(rd), value: result)

                if EmulatorDebugTools.shared.isDebugModeEnabled {
                    print("  FDIV D\(rd), D\(rn), D\(rm): \(a) / \(b) = \(result)")
                }
            }
        }
    }

    // MARK: - 浮点内存访问指令实现

    /// 执行浮点加载指令 (LDR)
    private func executeFPLoad(_ instruction: UInt32) throws {
        // 确保内存访问可用
        guard let memory = self.memory else {
            throw EmulatorError.deviceError(message: "浮点加载需要内存访问，但内存未连接")
        }

        let rt = Int(instruction & 0x1F) // 浮点目标寄存器
        let rn = Int((instruction >> 5) & 0x1F) // 基址寄存器
        let imm12 = (instruction >> 10) & 0xFFF // 立即数偏移
        let precision = getPrecision(instruction)

        // 获取基址
        let baseAddress = cpu.getRegister(UInt32(rn))
        let offset = UInt64(imm12) << 2 // 扩展为字节偏移
        let address = baseAddress + offset

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        switch precision {
        case .single:
            // 加载32位单精度值
            let value = try memory.read(at: address, size: 4)
            let floatValue = Float(bitPattern: UInt32(truncatingIfNeeded: value))
            cpu.setFloatRegister(UInt32(rt), value: floatValue)

            if debugMode {
                print("  LDR S\(rt), [X\(rn), #\(offset)]: 从地址 0x\(String(format:"%llX", address)) 加载 \(floatValue)")
            }
        case .double:
            // 加载64位双精度值
            let value = try memory.read(at: address, size: 8)
            let doubleValue = Double(bitPattern: value)
            cpu.setDoubleRegister(UInt32(rt), value: doubleValue)

            if debugMode {
                print("  LDR D\(rt), [X\(rn), #\(offset)]: 从地址 0x\(String(format:"%llX", address)) 加载 \(doubleValue)")
            }
        }
    }

    /// 执行浮点存储指令 (STR)
    private func executeFPStore(_ instruction: UInt32) throws {
        // 确保内存访问可用
        guard let memory = self.memory else {
            throw EmulatorError.deviceError(message: "浮点存储需要内存访问，但内存未连接")
        }

        let rt = Int(instruction & 0x1F) // 浮点源寄存器
        let rn = Int((instruction >> 5) & 0x1F) // 基址寄存器
        let imm12 = (instruction >> 10) & 0xFFF // 立即数偏移
        let precision = getPrecision(instruction)

        // 获取基址
        let baseAddress = cpu.getRegister(UInt32(rn))
        let offset = UInt64(imm12) << 2 // 扩展为字节偏移
        let address = baseAddress + offset

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        switch precision {
        case .single:
            // 存储32位单精度值
            let floatValue = cpu.getFloatRegister(UInt32(rt))
            let bits = floatValue.bitPattern
            try memory.write(at: address, value: UInt64(bits), size: 4)

            if debugMode {
                print("  STR S\(rt), [X\(rn), #\(offset)]: 将 \(floatValue) 存储到地址 0x\(String(format:"%llX", address))")
            }
        case .double:
            // 存储64位双精度值
            let doubleValue = cpu.getDoubleRegister(UInt32(rt))
            let bits = doubleValue.bitPattern
            try memory.write(at: address, value: bits, size: 8)

            if debugMode {
                print("  STR D\(rt), [X\(rn), #\(offset)]: 将 \(doubleValue) 存储到地址 0x\(String(format:"%llX", address))")
            }
        }
    }

    // MARK: - 浮点类型转换指令实现

    /// 执行浮点格式转换指令 (FCVT)
    private func executeFPCvt(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let srcType = (instruction >> 16) & 0x3
        let dstType = (instruction >> 22) & 0x3

        // 源类型: 0=单精度, 1=双精度
        // 目标类型: 0=单精度, 1=双精度

        if srcType == 0 && dstType == 1 {
            // 单精度转双精度
            let singleValue = cpu.getFloatRegister(UInt32(rn))
            let doubleValue = Double(singleValue)
            cpu.setDoubleRegister(UInt32(rd), value: doubleValue)

            if EmulatorDebugTools.shared.isDebugModeEnabled {
                print("  FCVT D\(rd), S\(rn): \(singleValue) -> \(doubleValue)")
            }
        } else if srcType == 1 && dstType == 0 {
            // 双精度转单精度
            let doubleValue = cpu.getDoubleRegister(UInt32(rn))
            let singleValue = Float(doubleValue)
            cpu.setFloatRegister(UInt32(rd), value: singleValue)

            if EmulatorDebugTools.shared.isDebugModeEnabled {
                print("  FCVT S\(rd), D\(rn): \(doubleValue) -> \(singleValue)")
            }
        } else {
            throw EmulatorError.unsupportedInstructionFormat(
                format: "0x\(String(format: "%08X", instruction))",
                opcode: UInt8((instruction >> 24) & 0xFF),
                details: "不支持的浮点转换: 源类型=\(srcType), 目标类型=\(dstType)"
            )
        }
    }

    /// 执行浮点寄存器移动指令 (FMOV)
    private func executeFPMove(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let precision = getPrecision(instruction)

        // 检查指令格式
        let isGenericMove = (instruction & 0xFFE0FC00) == 0x1E204000
        let isIntToFloat = (instruction & 0xFFE0FC00) == 0x1E200000
        let isFloatToInt = (instruction & 0xFFE0FC00) == 0x1E260000

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            print("  FMOV指令格式: 通用移动=\(isGenericMove), 整数到浮点=\(isIntToFloat), 浮点到整数=\(isFloatToInt)")
            print("  寄存器: rd=\(rd), rn=\(rn), 精度=\(precision)")
        }

        if isGenericMove {
            // 浮点到浮点移动
            switch precision {
            case .single:
                let value = cpu.getFloatRegister(UInt32(rn))
                cpu.setFloatRegister(UInt32(rd), value: value)

                if debugMode {
                    print("  FMOV S\(rd), S\(rn): \(value)")
                }
            case .double:
                let value = cpu.getDoubleRegister(UInt32(rn))
                cpu.setDoubleRegister(UInt32(rd), value: value)

                if debugMode {
                    print("  FMOV D\(rd), D\(rn): \(value)")
                }
            }
        } else if isIntToFloat {
            // 整数到浮点移动
            let intValue = cpu.getRegister(UInt32(rn))
            switch precision {
            case .single:
                let floatBits = UInt32(truncatingIfNeeded: intValue)
                let floatValue = Float(bitPattern: floatBits)
                cpu.setFloatRegister(UInt32(rd), value: floatValue)

                if debugMode {
                    print("  FMOV S\(rd), X\(rn): 0x\(String(format:"%X", intValue)) -> \(floatValue)")
                }
            case .double:
                let doubleValue = Double(bitPattern: intValue)
                cpu.setDoubleRegister(UInt32(rd), value: doubleValue)

                if debugMode {
                    print("  FMOV D\(rd), X\(rn): 0x\(String(format:"%X", intValue)) -> \(doubleValue)")
                }
            }
        } else if isFloatToInt {
            // 浮点到整数移动
            switch precision {
            case .single:
                let floatValue = cpu.getFloatRegister(UInt32(rn))
                let bits = UInt64(floatValue.bitPattern)
                cpu.setRegister(UInt32(rd), value: bits)

                if debugMode {
                    print("  FMOV X\(rd), S\(rn): \(floatValue) -> 0x\(String(format:"%X", bits))")
                }
            case .double:
                let doubleValue = cpu.getDoubleRegister(UInt32(rn))
                cpu.setRegister(UInt32(rd), value: doubleValue.bitPattern)

                if debugMode {
                    print("  FMOV X\(rd), D\(rn): \(doubleValue) -> 0x\(String(format:"%X", doubleValue.bitPattern))")
                }
            }
        } else {
            if debugMode {
                print("  ⚠️ 不支持的FMOV指令格式: 0x\(String(format: "%08X", instruction))")
            }
        }
    }

    // MARK: - 浮点与整数转换指令实现

    /// 执行整数到浮点转换指令
    private func executeIntToFP(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let precision = getPrecision(instruction)
        let isSigned = ((instruction >> 16) & 0x1) == 0

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        // 检查是否是位模式移动指令 - 扩展匹配逻辑
        let isRawBitMove = (instruction & 0xFF3E0000) == 0x1E270000 ||
                          (instruction & 0xFF3E0000) == 0x9E670000 ||
                          instruction == 0x1E270020 ||
                          instruction == 0x1E270021

        if isRawBitMove || (((instruction >> 16) & 0xF) == 0x7) {
            // 执行位模式移动 - 直接将整数位模式复制到浮点寄存器
            let intValue = cpu.getRegister(UInt32(rn))
            if debugMode {
                print("  执行位模式移动: X\(rn)=0x\(String(format: "%X", intValue)) -> S\(rd)")
            }

            if precision == .single {
                // 将位模式作为单精度浮点数解读
                let bits = UInt32(truncatingIfNeeded: intValue)
                let floatValue = Float(bitPattern: bits)
                cpu.setFloatRegister(UInt32(rd), value: floatValue)

                if debugMode {
                    print("  FMOV S\(rd), X\(rn): 0x\(String(format: "%X", bits)) -> \(floatValue)")
                }
            } else {
                // 将位模式作为双精度浮点数解读
                let doubleValue = Double(bitPattern: intValue)
                cpu.setDoubleRegister(UInt32(rd), value: doubleValue)

                if debugMode {
                    print("  FMOV D\(rd), X\(rn): 0x\(String(format: "%X", intValue)) -> \(doubleValue)")
                }
            }
            return
        }

        // 原来的转换逻辑 (SCVTF/UCVTF)
        let intValue = cpu.getRegister(UInt32(rn))
        switch precision {
        case .single:
            let floatValue: Float
            if isSigned {
                floatValue = Float(Int64(bitPattern: intValue))
            } else {
                floatValue = Float(intValue)
            }
            cpu.setFloatRegister(UInt32(rd), value: floatValue)

            if debugMode {
                print("  \(isSigned ? "SCVTF" : "UCVTF") S\(rd), X\(rn): \(intValue) -> \(floatValue)")
            }
        case .double:
            let doubleValue: Double
            if isSigned {
                doubleValue = Double(Int64(bitPattern: intValue))
            } else {
                doubleValue = Double(intValue)
            }
            cpu.setDoubleRegister(UInt32(rd), value: doubleValue)

            if debugMode {
                print("  \(isSigned ? "SCVTF" : "UCVTF") D\(rd), X\(rn): \(intValue) -> \(doubleValue)")
            }
        }
    }

    /// 执行浮点到整数转换指令
    private func executeFPToInt(_ instruction: UInt32) throws {
        let rd = Int(instruction & 0x1F)
        let rn = Int((instruction >> 5) & 0x1F)
        let precision = getPrecision(instruction)
        let isSigned = ((instruction >> 16) & 0x1) == 0

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        if debugMode {
            // 打印详细指令信息
            print("  执行浮点到整数转换: \(isSigned ? "有符号" : "无符号"), 精度: \(precision == .single ? "单精度" : "双精度")")
            print("  寄存器: X\(rd) <- S\(rn)")
        }

        switch precision {
        case .single:
            let floatValue = cpu.getFloatRegister(UInt32(rn))
            let intValue = Int64(floatValue)  // 使用默认向零舍入
            cpu.setRegister(UInt32(rd), value: UInt64(bitPattern: intValue))

            if debugMode {
                print("  FCVTZS X\(rd), S\(rn): \(floatValue) -> \(intValue)")
            }
        case .double:
            let doubleValue = cpu.getDoubleRegister(UInt32(rn))
            let intValue = Int64(doubleValue)  // 使用默认向零舍入
            cpu.setRegister(UInt32(rd), value: UInt64(bitPattern: intValue))

            if debugMode {
                print("  FCVTZS X\(rd), D\(rn): \(doubleValue) -> \(intValue)")
            }
        }
    }

    /// 执行浮点比较指令
    private func executeFPCmp(_ instruction: UInt32) throws {
        let rn = Int((instruction >> 5) & 0x1F)
        let rm = Int((instruction >> 16) & 0x1F)
        let precision = getPrecision(instruction)

        let debugMode = EmulatorDebugTools.shared.isDebugModeEnabled

        func updateFlags() {
            // 修改CPU状态寄存器中的NZCV标志位
            var pstate: UInt64 = 0
            if nFlag { pstate |= 0x80000000 }
            if zFlag { pstate |= 0x40000000 }
            if cFlag { pstate |= 0x20000000 }
            if vFlag { pstate |= 0x10000000 }
            // 更新CPU标志位
            let currentFlags = cpu.getFPSR() & ~0xF0000000
            cpu.setFPSR(currentFlags | UInt32(pstate))
        }

        var nFlag = false
        var zFlag = false
        var cFlag = false
        var vFlag = false

        switch precision {
        case .single:
            let a = cpu.getFloatRegister(UInt32(rn))
            let b = cpu.getFloatRegister(UInt32(rm))

            if debugMode {
                print("  FCMP S\(rn), S\(rm): 比较 \(a) 与 \(b)")
            }

            // 处理NaN情况
            if a.isNaN || b.isNaN {
                nFlag = false
                zFlag = false
                cFlag = false
                vFlag = true // 设置V标志表示无序比较
            } else if a == b {
                nFlag = false
                zFlag = true
                cFlag = true
                vFlag = false
            } else if a < b {
                nFlag = true
                zFlag = false
                cFlag = false
                vFlag = false
            } else { // a > b
                nFlag = false
                zFlag = false
                cFlag = true
                vFlag = false
            }

        case .double:
            let a = cpu.getDoubleRegister(UInt32(rn))
            let b = cpu.getDoubleRegister(UInt32(rm))

            if debugMode {
                print("  FCMP D\(rn), D\(rm): 比较 \(a) 与 \(b)")
            }

            // 处理NaN情况
            if a.isNaN || b.isNaN {
                nFlag = false
                zFlag = false
                cFlag = false
                vFlag = true // 设置V标志表示无序比较
            } else if a == b {
                nFlag = false
                zFlag = true
                cFlag = true
                vFlag = false
            } else if a < b {
                nFlag = true
                zFlag = false
                cFlag = false
                vFlag = false
            } else { // a > b
                nFlag = false
                zFlag = false
                cFlag = true
                vFlag = false
            }
        }

        updateFlags()

        if debugMode {
            print("  FCMP 更新标志位: N=\(nFlag), Z=\(zFlag), C=\(cFlag), V=\(vFlag)")
        }
    }

    // 为FMUL创建特殊检测处理
    private func isActuallyFMul(_ instruction: UInt32) -> Bool {
        // 检查指令的特定模式，判断是否实际是乘法指令
        // 例如，如果指令是0x1E200804，这是乘法格式
        return (instruction & 0xFFE0FC00) == 0x1E200800
    }
}