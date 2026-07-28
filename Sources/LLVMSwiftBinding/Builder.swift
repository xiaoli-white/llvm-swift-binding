import cLLVM

final class Builder {
    let ref: LLVMBuilderRef
    let context: Context
    private var currentModule: Module?

    init(in context: Context) {
        self.ref = LLVMCreateBuilderInContext(context.ref)!
        self.context = context
    }

    deinit {
        LLVMDisposeBuilder(ref)
    }

    func positionAtEnd(of block: BasicBlock) {
        currentModule = block.module
        LLVMPositionBuilderAtEnd(ref, block.ref)
    }

    @discardableResult
    func buildRet(_ value: Value) -> ReturnInst {
        let inst = LLVMBuildRet(ref, value.ref)!
        return ReturnInst(ref: inst, context: context, module: currentModule)
    }

    @discardableResult
    func buildRetVoid() -> ReturnInst {
        let inst = LLVMBuildRetVoid(ref)!
        return ReturnInst(ref: inst, context: context, module: currentModule)
    }
}
