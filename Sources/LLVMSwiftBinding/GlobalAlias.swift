import cLLVM

final class GlobalAlias: Value {
    init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    var aliasee: Value? {
        guard let ref = LLVMAliasGetAliasee(ref) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }

    var aliaseeType: Type {
        context.wrapType(LLVMGlobalGetValueType(ref))
    }
}

final class GlobalIFunc: Value {
    init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    var resolver: Value? {
        guard let ref = LLVMGetGlobalIFuncResolver(ref) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }
}
