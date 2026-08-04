import cLLVM

public final class Function: Value {
    public init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    public func appendBasicBlock(_ name: String) -> BasicBlock {
        let block = LLVMAppendBasicBlockInContext(context.ref, ref, name)!
        return BasicBlock(ref: block, function: self, module: module!)
    }

    public var parameterCount: UInt32 {
        LLVMCountParams(ref)
    }

    public func parameter(at index: UInt32) -> Argument {
        Argument(ref: LLVMGetParam(ref, index)!, function: self, module: module!)
    }

    public var entryBlock: BasicBlock? {
        guard let block = LLVMGetEntryBasicBlock(ref) else { return nil }
        return BasicBlock(ref: block, function: self, module: module!)
    }

    public var basicBlockCount: UInt32 {
        LLVMCountBasicBlocks(ref)
    }

    public var basicBlocks: [BasicBlock] {
        var result: [BasicBlock] = []
        guard let first = LLVMGetFirstBasicBlock(ref) else { return [] }
        var current: LLVMBasicBlockRef? = first
        while let block = current {
            result.append(BasicBlock(ref: block, function: self, module: module!))
            current = LLVMGetNextBasicBlock(block)
        }
        return result
    }

    public var parameters: [Argument] {
        var result: [Argument] = []
        guard let first = LLVMGetFirstParam(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let param = current {
            result.append(Argument(ref: param, function: self, module: module!))
            current = LLVMGetNextParam(param)
        }
        return result
    }

    public func setSubprogram(_ sp: Metadata) {
        LLVMSetSubprogram(ref, sp.ref)
    }

    public var subprogram: Metadata? {
        guard let sp = LLVMGetSubprogram(ref) else { return nil }
        return Metadata(ref: sp)
    }

    public var personality: Function? {
        get {
            guard let fn = LLVMGetPersonalityFn(ref) else { return nil }
            return Function(ref: fn, module: module!)
        }
        set {
            LLVMSetPersonalityFn(ref, newValue?.ref)
        }
    }

    public var gc: String? {
        get {
            guard let ptr = LLVMGetGC(ref) else { return nil }
            return String(cString: ptr)
        }
        set {
            LLVMSetGC(ref, newValue)
        }
    }

    public var linkage: LLVMLinkage {
        get { LLVMGetLinkage(ref) }
        set { LLVMSetLinkage(ref, newValue) }
    }

    public var callConv: LLVMCallConv {
        get { LLVMCallConv(rawValue: LLVMGetFunctionCallConv(ref)) }
        set { LLVMSetFunctionCallConv(ref, newValue.rawValue) }
    }
}
