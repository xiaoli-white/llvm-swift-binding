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
}

final class Argument: Value {
    init(ref: LLVMValueRef, function: Function, module: Module) {
        super.init(ref: ref, context: function.context, module: module)
    }
}
