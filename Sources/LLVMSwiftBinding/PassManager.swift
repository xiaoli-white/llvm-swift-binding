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
}
