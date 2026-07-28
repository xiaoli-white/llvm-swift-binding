import cLLVM

final class LLJIT {
    let ref: LLVMOrcLLJITRef

    init() throws {
        TargetMachine.initializeAllTargets()
        let builder = LLVMOrcCreateLLJITBuilder()
        var jit: LLVMOrcLLJITRef? = nil
        let err = LLVMOrcCreateLLJIT(&jit, builder)
        if err != nil {
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to create LLJIT: \(msg)")
        }
        self.ref = jit!
    }

    deinit {
        let err = LLVMOrcDisposeLLJIT(ref)
        if err != nil {
            LLVMConsumeError(err)
        }
    }

    var dataLayout: String {
        String(cString: LLVMOrcLLJITGetDataLayoutStr(ref))
    }

    var triple: String {
        String(cString: LLVMOrcLLJITGetTripleString(ref))
    }

    func addModule(_ module: Module) throws {
        let tsm = LLVMOrcCreateNewThreadSafeModule(module.ref, module.context.ref)
        defer { LLVMOrcDisposeThreadSafeModule(tsm) }
        let dylib = LLVMOrcLLJITGetMainJITDylib(ref)
        let err = LLVMOrcLLJITAddLLVMIRModule(ref, dylib, tsm)
        if err != nil {
            let msg = errorMessage(from: err!)
            throw LLVMError.emitFailed(message: "failed to add IR module: \(msg)")
        }
    }

    func lookup(_ name: String) throws -> UInt64 {
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

    func runFunction(_ name: String) throws -> Int32 {
        let address = try lookup(name)
        let fn = unsafeBitCast(UInt(address), to: (@convention(c) () -> Int32).self)
        return fn()
    }
}
