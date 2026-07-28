import cLLVM

extension Module {
    static func parseIR(_ ir: String, in context: Context, bufferName: String = "ir") throws -> Module {
        let memBuf = MemoryBuffer.fromString(ir, bufferName: bufferName)
        var outModule: LLVMModuleRef? = nil
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = LLVMParseIRInContext2(context.ref, memBuf.ref, &outModule, &errMsg)
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.parseFailed(message: msg)
        }
        return Module(ref: outModule!, context: context)
    }

    static func parseIRFile(_ path: String, in context: Context) throws -> Module {
        let memBuf = try MemoryBuffer.fromFile(path)
        var outModule: LLVMModuleRef? = nil
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = LLVMParseIRInContext2(context.ref, memBuf.ref, &outModule, &errMsg)
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.parseFailed(message: msg)
        }
        return Module(ref: outModule!, context: context)
    }

    static func parseBitcode(_ data: [UInt8], in context: Context) throws -> Module {
        let memBuf = MemoryBuffer.fromBytes(data, bufferName: "bitcode")
        var outModule: LLVMModuleRef? = nil
        let result = LLVMParseBitcodeInContext2(context.ref, memBuf.ref, &outModule)
        if result != 0 {
            throw LLVMError.parseFailed(message: "failed to parse bitcode")
        }
        return Module(ref: outModule!, context: context)
    }

    static func parseBitcodeFile(_ path: String, in context: Context) throws -> Module {
        let memBuf = try MemoryBuffer.fromFile(path)
        var outModule: LLVMModuleRef? = nil
        let result = LLVMParseBitcodeInContext2(context.ref, memBuf.ref, &outModule)
        if result != 0 {
            throw LLVMError.parseFailed(message: "failed to parse bitcode")
        }
        return Module(ref: outModule!, context: context)
    }

    func writeBitcode(to path: String) throws {
        let result = path.withCString { pathPtr -> Int32 in
            LLVMWriteBitcodeToFile(ref, pathPtr)
        }
        if result != 0 {
            throw LLVMError.emitFailed(message: "failed to write bitcode to \(path)")
        }
    }

    func writeBitcodeToMemoryBuffer() -> MemoryBuffer {
        let buf = LLVMWriteBitcodeToMemoryBuffer(ref)!
        return MemoryBuffer(ref: buf)
    }
}
