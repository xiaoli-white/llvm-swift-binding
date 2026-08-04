import cLLVM

class Value {
    let ref: LLVMValueRef
    let context: Context
    let module: Module?

    init(ref: LLVMValueRef, context: Context, module: Module? = nil) {
        self.ref = ref
        self.context = context
        self.module = module
    }

    var type: Type {
        context.wrapType(LLVMTypeOf(ref))
    }

    var name: String {
        get { String(cString: LLVMGetValueName(ref)) }
        set { LLVMSetValueName(ref, newValue) }
    }

    var hasMetadata: Bool {
        LLVMHasMetadata(ref) != 0
    }

    func setMetadata(kind: UInt32, _ node: Value?) {
        LLVMSetMetadata(ref, kind, node?.ref)
    }

    func getMetadata(kind: UInt32) -> Value? {
        guard let ref = LLVMGetMetadata(ref, kind) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }
}

final class Argument: Value {
    init(ref: LLVMValueRef, function: Function, module: Module) {
        super.init(ref: ref, context: function.context, module: module)
    }
}
