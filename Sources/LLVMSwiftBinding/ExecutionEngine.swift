import cLLVM

public final class GenericValue {
    public let ref: LLVMGenericValueRef

    public init(ref: LLVMGenericValueRef) {
        self.ref = ref
    }

    deinit {
        LLVMDisposeGenericValue(ref)
    }

    public static func ofInt(_ value: UInt64, type: LLVMType, isSigned: Bool = false) -> GenericValue {
        GenericValue(ref: LLVMCreateGenericValueOfInt(type.ref, value, isSigned ? 1 : 0))
    }

    public static func ofPointer(_ pointer: UnsafeMutableRawPointer?) -> GenericValue {
        GenericValue(ref: LLVMCreateGenericValueOfPointer(pointer))
    }

    public static func ofFloat(_ value: Double, type: LLVMType) -> GenericValue {
        GenericValue(ref: LLVMCreateGenericValueOfFloat(type.ref, value))
    }

    public var intWidth: UInt32 {
        LLVMGenericValueIntWidth(ref)
    }

    public func toInt(isSigned: Bool) -> UInt64 {
        LLVMGenericValueToInt(ref, isSigned ? 1 : 0)
    }

    public var pointer: UnsafeMutableRawPointer? {
        LLVMGenericValueToPointer(ref)
    }

    public func toFloat(type: LLVMType) -> Double {
        LLVMGenericValueToFloat(type.ref, ref)
    }
}

public final class ExecutionEngine {
    public let ref: LLVMExecutionEngineRef
    private let module: Module?

    public init(module: Module, optLevel: UInt32 = 0) throws {
        var options = LLVMMCJITCompilerOptions()
        LLVMInitializeMCJITCompilerOptions(&options, MemoryLayout<LLVMMCJITCompilerOptions>.size)
        options.OptLevel = optLevel
        var engine: LLVMExecutionEngineRef?
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = LLVMCreateMCJITCompilerForModule(
            &engine, module.ref, &options, MemoryLayout<LLVMMCJITCompilerOptions>.size, &errMsg
        )
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.emitFailed(message: "failed to create execution engine: \(msg)")
        }
        ref = engine!
        self.module = module
        module.ownsRef = false
    }

    deinit {
        LLVMDisposeExecutionEngine(ref)
    }

    public func runFunction(_ function: Function, args: [GenericValue] = []) -> GenericValue? {
        var argRefs: [LLVMGenericValueRef?] = args.map(\.ref)
        let result = argRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMRunFunction(ref, function.ref, UInt32(args.count), buffer.baseAddress)
        }
        guard let result else { return nil }
        return GenericValue(ref: result)
    }

    public func functionAddress(_ name: String) -> UInt64 {
        name.withCString { namePtr in
            LLVMGetFunctionAddress(ref, namePtr)
        }
    }

    public func pointerToGlobal(_ global: GlobalVariable) -> UnsafeMutableRawPointer? {
        LLVMGetPointerToGlobal(ref, global.ref)
    }

    public func addModule(_ module: Module) {
        LLVMAddModule(ref, module.ref)
        module.ownsRef = false
    }

    public func findFunction(_ name: String) -> Function? {
        var outFn: LLVMValueRef?
        let result = name.withCString { namePtr -> Int32 in
            LLVMFindFunction(ref, namePtr, &outFn)
        }
        guard result == 0, let outFn, let module else { return nil }
        return Function(ref: outFn, module: module)
    }

    public func runStaticConstructors() {
        LLVMRunStaticConstructors(ref)
    }

    public func runStaticDestructors() {
        LLVMRunStaticDestructors(ref)
    }

    public func removeModule(_ module: Module) throws -> Module {
        var outMod: LLVMModuleRef? = nil
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = LLVMRemoveModule(ref, module.ref, &outMod, &errMsg)
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.emitFailed(message: "failed to remove module: \(msg)")
        }
        return Module(ref: outMod!, context: module.context)
    }

    public func addGlobalMapping(_ global: GlobalVariable, to pointer: UnsafeMutableRawPointer) {
        LLVMAddGlobalMapping(ref, global.ref, pointer)
    }

    public func globalValueAddress(_ name: String) -> UInt64 {
        name.withCString { namePtr in
            LLVMGetGlobalValueAddress(ref, namePtr)
        }
    }

    public var targetData: DataLayout {
        DataLayout(ref: LLVMGetExecutionEngineTargetData(ref), owns: false)
    }

    public var targetMachine: TargetMachine {
        TargetMachine(ref: LLVMGetExecutionEngineTargetMachine(ref))
    }

    public var lastErrorMessage: String? {
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = LLVMExecutionEngineGetErrMsg(ref, &errMsg)
        guard result != 0, let errMsg else { return nil }
        return String(cString: errMsg)
    }

    public func runFunctionAsMain(_ function: Function, args: [String] = [], env: [String] = []) -> Int32 {
        let argv: [UnsafeMutablePointer<CChar>?] = args.map(cString)
        let envp: [UnsafeMutablePointer<CChar>?] = env.map(cString)
        defer {
            argv.forEach { $0?.deallocate() }
            envp.forEach { $0?.deallocate() }
        }
        let result = argv.withUnsafeBufferPointer { argvBuf in
            envp.withUnsafeBufferPointer { envpBuf in
                let argsPtr = argvBuf.baseAddress.map {
                    UnsafeRawPointer($0).assumingMemoryBound(to: UnsafePointer<CChar>?.self)
                }
                let envPtr = envpBuf.baseAddress.map {
                    UnsafeRawPointer($0).assumingMemoryBound(to: UnsafePointer<CChar>?.self)
                }
                return LLVMRunFunctionAsMain(ref, function.ref, UInt32(args.count), argsPtr, envPtr)
            }
        }
        return result
    }

    public func freeMachineCode(for function: Function) {
        LLVMFreeMachineCodeForFunction(ref, function.ref)
    }
}
