import cLLVM

final class PassManager {
    let ref: LLVMPassManagerRef

    init() {
        self.ref = LLVMCreatePassManager()
    }

    init(module: Module) {
        self.ref = LLVMCreateFunctionPassManagerForModule(module.ref)
    }

    deinit {
        LLVMDisposePassManager(ref)
    }

    func addAnalysisPasses(of targetMachine: TargetMachine) {
        LLVMAddAnalysisPasses(targetMachine.ref, ref)
    }

    @discardableResult
    func run(on module: Module) -> Bool {
        LLVMRunPassManager(ref, module.ref) != 0
    }

    @discardableResult
    func initialize() -> Bool {
        LLVMInitializeFunctionPassManager(ref) != 0
    }

    @discardableResult
    func run(on function: Function) -> Bool {
        LLVMRunFunctionPassManager(ref, function.ref) != 0
    }

    @discardableResult
    func finalize() -> Bool {
        LLVMFinalizeFunctionPassManager(ref) != 0
    }

    func runPasses(_ passes: String, on module: Module, targetMachine: TargetMachine? = nil, options: PassBuilderOptions? = nil) throws {
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

    func runPassesOnFunction(_ passes: String, function: Function, targetMachine: TargetMachine? = nil, options: PassBuilderOptions? = nil) throws {
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

final class PassBuilderOptions {
    let ref: LLVMPassBuilderOptionsRef

    init() {
        self.ref = LLVMCreatePassBuilderOptions()
    }

    deinit {
        LLVMDisposePassBuilderOptions(ref)
    }

    func setVerifyEach(_ value: Bool) {
        LLVMPassBuilderOptionsSetVerifyEach(ref, value ? 1 : 0)
    }

    func setDebugLogging(_ value: Bool) {
        LLVMPassBuilderOptionsSetDebugLogging(ref, value ? 1 : 0)
    }

    func setLoopInterleaving(_ value: Bool) {
        LLVMPassBuilderOptionsSetLoopInterleaving(ref, value ? 1 : 0)
    }

    func setLoopVectorization(_ value: Bool) {
        LLVMPassBuilderOptionsSetLoopVectorization(ref, value ? 1 : 0)
    }

    func setSLPVectorization(_ value: Bool) {
        LLVMPassBuilderOptionsSetSLPVectorization(ref, value ? 1 : 0)
    }

    func setLoopUnrolling(_ value: Bool) {
        LLVMPassBuilderOptionsSetLoopUnrolling(ref, value ? 1 : 0)
    }

    func setCallGraphProfile(_ value: Bool) {
        LLVMPassBuilderOptionsSetCallGraphProfile(ref, value ? 1 : 0)
    }

    func setMergeFunctions(_ value: Bool) {
        LLVMPassBuilderOptionsSetMergeFunctions(ref, value ? 1 : 0)
    }

    func setInlinerThreshold(_ value: Int32) {
        LLVMPassBuilderOptionsSetInlinerThreshold(ref, value)
    }
}
