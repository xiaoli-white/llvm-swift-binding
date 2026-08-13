import cLLVM

public final class LLJIT {
    public let ref: LLVMOrcLLJITRef

    public init() throws {
        TargetMachine.initializeAllTargets()
        let builder = LLVMOrcCreateLLJITBuilder()
        var jit: LLVMOrcLLJITRef?
        let err = LLVMOrcCreateLLJIT(&jit, builder)
        if err != nil {
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to create LLJIT: \(msg)")
        }
        ref = jit!
    }

    deinit {
        let err = LLVMOrcDisposeLLJIT(ref)
        if err != nil {
            LLVMConsumeError(err)
        }
    }

    public var dataLayout: String {
        String(cString: LLVMOrcLLJITGetDataLayoutStr(ref))
    }

    public var triple: String {
        String(cString: LLVMOrcLLJITGetTripleString(ref))
    }

    public var globalPrefix: Character {
        Character(UnicodeScalar(UInt8(bitPattern: LLVMOrcLLJITGetGlobalPrefix(ref))))
    }

    public func enableDebugSupport() throws {
        let err = LLVMOrcLLJITEnableDebugSupport(ref)
        if err != nil {
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to enable debug support: \(msg)")
        }
    }

    public func addModule(_ module: Module) throws {
        let tsc = LLVMOrcCreateNewThreadSafeContextFromLLVMContext(module.context.ref)
        defer { LLVMOrcDisposeThreadSafeContext(tsc) }
        let tsm = LLVMOrcCreateNewThreadSafeModule(module.ref, tsc)
        let dylib = LLVMOrcLLJITGetMainJITDylib(ref)
        let err = LLVMOrcLLJITAddLLVMIRModule(ref, dylib, tsm)
        if err != nil {
            LLVMOrcDisposeThreadSafeModule(tsm)
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to add IR module: \(msg)")
        }
        module.ownsRef = false
        module.context.ownsRef = false
    }

    public func addObjectFile(_ buffer: MemoryBuffer) throws {
        let dylib = LLVMOrcLLJITGetMainJITDylib(ref)
        let err = LLVMOrcLLJITAddObjectFile(ref, dylib, buffer.ref)
        if err != nil {
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to add object file: \(msg)")
        }
        buffer.disown()
    }

    public func lookup(_ name: String) throws -> UInt64 {
        var address = LLVMOrcExecutorAddress(0)
        let err = name.withCString { namePtr in
            LLVMOrcLLJITLookup(ref, &address, namePtr)
        }
        if err != nil {
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to lookup \(name): \(msg)")
        }
        return UInt64(address)
    }
}
