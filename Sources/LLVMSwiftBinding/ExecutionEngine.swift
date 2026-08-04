import cLLVM

final class GenericValue {
    let ref: LLVMGenericValueRef

    init(ref: LLVMGenericValueRef) {
        self.ref = ref
    }

    deinit {
        LLVMDisposeGenericValue(ref)
    }

    static func ofInt(_ value: UInt64, type: Type, isSigned: Bool = false) -> GenericValue {
        GenericValue(ref: LLVMCreateGenericValueOfInt(type.ref, value, isSigned ? 1 : 0))
    }

    static func ofPointer(_ pointer: UnsafeMutableRawPointer?) -> GenericValue {
        GenericValue(ref: LLVMCreateGenericValueOfPointer(pointer))
    }

    static func ofFloat(_ value: Double, type: Type) -> GenericValue {
        GenericValue(ref: LLVMCreateGenericValueOfFloat(type.ref, value))
    }

    var intWidth: UInt32 {
        LLVMGenericValueIntWidth(ref)
    }

    func toInt(isSigned: Bool) -> UInt64 {
        LLVMGenericValueToInt(ref, isSigned ? 1 : 0)
    }

    var pointer: UnsafeMutableRawPointer? {
        LLVMGenericValueToPointer(ref)
    }

    func toFloat(type: Type) -> Double {
        LLVMGenericValueToFloat(type.ref, ref)
    }
}

final class ExecutionEngine {
    let ref: LLVMExecutionEngineRef
    private let module: Module?

    init(module: Module, optLevel: UInt32 = 0) throws {
        var options = LLVMMCJITCompilerOptions()
        LLVMInitializeMCJITCompilerOptions(&options, MemoryLayout<LLVMMCJITCompilerOptions>.size)
        options.OptLevel = optLevel
        var engine: LLVMExecutionEngineRef? = nil
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = LLVMCreateMCJITCompilerForModule(
            &engine, module.ref, &options, MemoryLayout<LLVMMCJITCompilerOptions>.size, &errMsg
        )
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.emitFailed(message: "failed to create execution engine: \(msg)")
        }
        self.ref = engine!
        self.module = module
        module.ownsRef = false
    }

    deinit {
        LLVMDisposeExecutionEngine(ref)
    }

    func runFunction(_ function: Function, args: [GenericValue] = []) -> GenericValue? {
        var argRefs: [LLVMGenericValueRef?] = args.map { $0.ref }
        let result = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMRunFunction(ref, function.ref, UInt32(args.count), buffer.baseAddress)
        }
        guard let result else { return nil }
        return GenericValue(ref: result)
    }

    func functionAddress(_ name: String) -> UInt64 {
        name.withCString { namePtr in
            LLVMGetFunctionAddress(ref, namePtr)
        }
    }

    func pointerToGlobal(_ global: GlobalVariable) -> UnsafeMutableRawPointer? {
        LLVMGetPointerToGlobal(ref, global.ref)
    }

    func addModule(_ module: Module) {
        LLVMAddModule(ref, module.ref)
        module.ownsRef = false
    }

    func findFunction(_ name: String) -> Function? {
        var outFn: LLVMValueRef? = nil
        let result = name.withCString { namePtr -> Int32 in
            LLVMFindFunction(ref, namePtr, &outFn)
        }
        guard result == 0, let outFn, let module else { return nil }
        return Function(ref: outFn, module: module)
    }

    func runStaticConstructors() {
        LLVMRunStaticConstructors(ref)
    }

    func runStaticDestructors() {
        LLVMRunStaticDestructors(ref)
    }
}
