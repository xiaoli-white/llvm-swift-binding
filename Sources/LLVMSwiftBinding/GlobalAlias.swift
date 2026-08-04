import cLLVM

public final class GlobalAlias: Value {
    public init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    public var aliasee: Value? {
        guard let ref = LLVMAliasGetAliasee(ref) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }

    public var aliaseeType: Type {
        context.wrapType(LLVMGlobalGetValueType(ref))
    }
}

public final class GlobalIFunc: Value {
    public init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    public var resolver: Value? {
        guard let ref = LLVMGetGlobalIFuncResolver(ref) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }
}
