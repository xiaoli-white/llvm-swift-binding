import cLLVM

final class BasicBlock {
    let ref: LLVMBasicBlockRef
    let function: Function
    let module: Module

    init(ref: LLVMBasicBlockRef, function: Function, module: Module) {
        self.ref = ref
        self.function = function
        self.module = module
    }

    var context: Context { module.context }
}
