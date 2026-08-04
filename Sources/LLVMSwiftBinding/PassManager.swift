import cLLVM

public final class PassManager {
    public let ref: LLVMPassManagerRef

    public init() {
        self.ref = LLVMCreatePassManager()
    }

    public init(module: Module) {
        self.ref = LLVMCreateFunctionPassManagerForModule(module.ref)
    }

    deinit {
        LLVMDisposePassManager(ref)
    }

    public func addAnalysisPasses(of targetMachine: TargetMachine) {
        LLVMAddAnalysisPasses(targetMachine.ref, ref)
    }

    @discardableResult
    public func run(on module: Module) -> Bool {
        LLVMRunPassManager(ref, module.ref) != 0
    }

    @discardableResult
    public func initialize() -> Bool {
        LLVMInitializeFunctionPassManager(ref) != 0
    }

    @discardableResult
    public func run(on function: Function) -> Bool {
        LLVMRunFunctionPassManager(ref, function.ref) != 0
    }

    @discardableResult
    public func finalize() -> Bool {
        LLVMFinalizeFunctionPassManager(ref) != 0
    }

    public func runPasses(_ passes: String, on module: Module, targetMachine: TargetMachine? = nil, options: PassBuilderOptions? = nil) throws {
        let errorRef = passes.withCString { passPtr in
            LLVMRunPasses(module.ref, passPtr, targetMachine?.ref, options?.ref)
        }
        if let errorRef {
            let messagePtr = LLVMGetErrorMessage(errorRef)!
            let message = String(cString: messagePtr)
            LLVMDisposeErrorMessage(messagePtr)
            throw LLVMError.passRunFailed(message: message)
        }
    }

    public func runPassesOnFunction(_ passes: String, function: Function, targetMachine: TargetMachine? = nil, options: PassBuilderOptions? = nil) throws {
        let errorRef = passes.withCString { passPtr in
            LLVMRunPassesOnFunction(function.ref, passPtr, targetMachine?.ref, options?.ref)
        }
        if let errorRef {
            let messagePtr = LLVMGetErrorMessage(errorRef)!
            let message = String(cString: messagePtr)
            LLVMDisposeErrorMessage(messagePtr)
            throw LLVMError.passRunFailed(message: message)
        }
    }
}

public final class PassBuilderOptions {
    public let ref: LLVMPassBuilderOptionsRef

    public init() {
        self.ref = LLVMCreatePassBuilderOptions()
    }

    deinit {
        LLVMDisposePassBuilderOptions(ref)
    }

    public func setVerifyEach(_ value: Bool) {
        LLVMPassBuilderOptionsSetVerifyEach(ref, value ? 1 : 0)
    }

    public func setDebugLogging(_ value: Bool) {
        LLVMPassBuilderOptionsSetDebugLogging(ref, value ? 1 : 0)
    }

    public func setLoopInterleaving(_ value: Bool) {
        LLVMPassBuilderOptionsSetLoopInterleaving(ref, value ? 1 : 0)
    }

    public func setLoopVectorization(_ value: Bool) {
        LLVMPassBuilderOptionsSetLoopVectorization(ref, value ? 1 : 0)
    }

    public func setSLPVectorization(_ value: Bool) {
        LLVMPassBuilderOptionsSetSLPVectorization(ref, value ? 1 : 0)
    }

    public func setLoopUnrolling(_ value: Bool) {
        LLVMPassBuilderOptionsSetLoopUnrolling(ref, value ? 1 : 0)
    }

    public func setCallGraphProfile(_ value: Bool) {
        LLVMPassBuilderOptionsSetCallGraphProfile(ref, value ? 1 : 0)
    }

    public func setMergeFunctions(_ value: Bool) {
        LLVMPassBuilderOptionsSetMergeFunctions(ref, value ? 1 : 0)
    }

    public func setInlinerThreshold(_ value: Int32) {
        LLVMPassBuilderOptionsSetInlinerThreshold(ref, value)
    }
}
