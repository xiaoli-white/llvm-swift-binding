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
        let tsm = LLVMOrcCreateNewThreadSafeModule(module.ref, module.context.ref)
        defer { LLVMOrcDisposeThreadSafeModule(tsm) }
        let dylib = LLVMOrcLLJITGetMainJITDylib(ref)
        let err = LLVMOrcLLJITAddLLVMIRModule(ref, dylib, tsm)
        if err != nil {
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to add IR module: \(msg)")
        }
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

    public func runFunction(_ name: String) throws -> Int32 {
        let address = try lookup(name)
        let fn = unsafeBitCast(UInt(address), to: (@convention(c) () -> Int32).self)
        return fn()
    }
}
