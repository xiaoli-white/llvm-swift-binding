import cLLVM

final class Module {
    let ref: LLVMModuleRef
    let context: Context
    var ownsRef: Bool = true

    init(name: String, in context: Context) {
        self.ref = LLVMModuleCreateWithNameInContext(name, context.ref)!
        self.context = context
    }

    init(ref: LLVMModuleRef, context: Context) {
        self.ref = ref
        self.context = context
    }

    deinit {
        if ownsRef {
            LLVMDisposeModule(ref)
        }
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

    func addNamedMetadataOperand(_ name: String, _ node: Value) {
        name.withCString { namePtr in
            LLVMAddNamedMetadataOperand(ref, namePtr, node.ref)
        }
    }

    func namedMetadataOperandCount(_ name: String) -> UInt32 {
        name.withCString { namePtr in
            LLVMGetNamedMetadataNumOperands(ref, namePtr)
        }
    }

    func namedMetadataOperands(_ name: String) -> [Value] {
        let count = Int(namedMetadataOperandCount(name))
        guard count > 0 else { return [] }
        var nodes = [LLVMValueRef?](repeating: nil, count: count)
        nodes.withUnsafeMutableBufferPointer { buffer in
            name.withCString { namePtr in
                LLVMGetNamedMetadataOperands(ref, namePtr, buffer.baseAddress)
            }
        }
        return nodes.map { Value(ref: $0!, context: context, module: self) }
    }
}
