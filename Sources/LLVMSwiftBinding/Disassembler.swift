import cLLVM

public final class Disassembler {
    public let ref: LLVMDisasmContextRef

    public init?(triple: String, cpu: String = "", features: String = "") {
        let context = triple.withCString { triplePtr in
            cpu.withCString { cpuPtr in
                features.withCString { featuresPtr in
                    LLVMCreateDisasmCPUFeatures(triplePtr, cpuPtr, featuresPtr, nil, 0, nil, nil)
                }
            }
        }
        guard let context else { return nil }
        ref = context
    }

    deinit {
        LLVMDisasmDispose(ref)
    }

    @discardableResult
    public func setOptions(_ options: UInt64) -> Bool {
        LLVMSetDisasmOptions(ref, options) != 0
    }

    public func disassemble(_ bytes: [UInt8], pc: UInt64 = 0) -> [String] {
        var instructions: [String] = []
        var index = 0
        var address = pc
        while index < bytes.count {
            let remaining = Array(bytes[index...])
            var out = [CChar](repeating: 0, count: 256)
            let consumed = remaining.withUnsafeBufferPointer { buffer in
                LLVMDisasmInstruction(
                    ref,
                    UnsafeMutablePointer(mutating: buffer.baseAddress!),
                    UInt64(remaining.count),
                    address,
                    &out,
                    out.count
                )
            }
            if consumed == 0 {
                break
            }
            instructions.append(out.withUnsafeBufferPointer { String(cString: $0.baseAddress!) })
            index += Int(consumed)
            address += UInt64(consumed)
        }
        return instructions
    }
}
