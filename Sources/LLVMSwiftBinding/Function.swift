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

    var basicBlockCount: UInt32 {
        LLVMCountBasicBlocks(ref)
    }

    var basicBlocks: [BasicBlock] {
        var result: [BasicBlock] = []
        guard let first = LLVMGetFirstBasicBlock(ref) else { return [] }
        var current: LLVMBasicBlockRef? = first
        while let block = current {
            result.append(BasicBlock(ref: block, function: self, module: module!))
            current = LLVMGetNextBasicBlock(block)
        }
        return result
    }

    var parameters: [Argument] {
        var result: [Argument] = []
        guard let first = LLVMGetFirstParam(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let param = current {
            result.append(Argument(ref: param, function: self, module: module!))
            current = LLVMGetNextParam(param)
        }
        return result
    }

    func setSubprogram(_ sp: Metadata) {
        LLVMSetSubprogram(ref, sp.ref)
    }

    var subprogram: Metadata? {
        guard let sp = LLVMGetSubprogram(ref) else { return nil }
        return Metadata(ref: sp)
    }

    var personality: Function? {
        get {
            guard let fn = LLVMGetPersonalityFn(ref) else { return nil }
            return Function(ref: fn, module: module!)
        }
        set {
            LLVMSetPersonalityFn(ref, newValue?.ref)
        }
    }

    var gc: String? {
        get {
            guard let ptr = LLVMGetGC(ref) else { return nil }
            return String(cString: ptr)
        }
        set {
            LLVMSetGC(ref, newValue)
        }
    }

    var linkage: LLVMLinkage {
        get { LLVMGetLinkage(ref) }
        set { LLVMSetLinkage(ref, newValue) }
    }
}
