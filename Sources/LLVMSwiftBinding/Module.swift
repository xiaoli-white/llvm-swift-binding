import cLLVM

final class Module {
    let ref: LLVMModuleRef
    let context: Context

    init(name: String, in context: Context) {
        self.ref = LLVMModuleCreateWithNameInContext(name, context.ref)!
        self.context = context
    }

    deinit {
        LLVMDisposeModule(ref)
    }

    func dump() {
        LLVMDumpModule(ref)
    }

    var irString: String {
        let ptr = LLVMPrintModuleToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    func addFunction(_ name: String, type: FunctionType) -> Function {
        let funcRef = LLVMAddFunction(ref, name, type.ref)!
        return Function(ref: funcRef, module: self)
    }

    func addGlobal(_ name: String, type: Type) -> GlobalVariable {
        let ref = LLVMAddGlobal(self.ref, type.ref, name)!
        return GlobalVariable(ref: ref, module: self)
    }

    var target: String {
        get { String(cString: LLVMGetTarget(ref)!) }
        set { LLVMSetTarget(ref, newValue) }
    }
}
