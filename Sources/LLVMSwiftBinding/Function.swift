import cLLVM

final class Function: Value {
    init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    func appendBasicBlock(_ name: String) -> BasicBlock {
        let block = LLVMAppendBasicBlockInContext(context.ref, ref, name)!
        return BasicBlock(ref: block, function: self, module: module!)
    }

    var parameterCount: UInt32 {
        LLVMCountParams(ref)
    }

    func parameter(at index: UInt32) -> Argument {
        Argument(ref: LLVMGetParam(ref, index)!, function: self, module: module!)
    }

    var entryBlock: BasicBlock? {
        guard let block = LLVMGetEntryBasicBlock(ref) else { return nil }
        return BasicBlock(ref: block, function: self, module: module!)
    }

    func setSubprogram(_ sp: Metadata) {
        LLVMSetSubprogram(ref, sp.ref)
    }

    var subprogram: Metadata? {
        guard let sp = LLVMGetSubprogram(ref) else { return nil }
        return Metadata(ref: sp)
    }
}
