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

    var isConstant: Bool {
        LLVMIsConstant(ref) != 0
    }

    var isUndef: Bool {
        LLVMIsUndef(ref) != 0
    }

    var isNull: Bool {
        LLVMIsNull(ref) != 0
    }

    var isPoison: Bool {
        LLVMIsPoison(ref) != 0
    }

    var isDeclaration: Bool {
        LLVMIsDeclaration(ref) != 0
    }

    var visibility: LLVMVisibility {
        get { LLVMGetVisibility(ref) }
        set { LLVMSetVisibility(ref, newValue) }
    }

    var dllStorageClass: LLVMDLLStorageClass {
        get { LLVMGetDLLStorageClass(ref) }
        set { LLVMSetDLLStorageClass(ref, newValue) }
    }

    var description: String {
        let ptr = LLVMPrintValueToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    var valueKind: LLVMValueKind {
        LLVMGetValueKind(ref)
    }

    var numOperands: UInt32 {
        UInt32(LLVMGetNumOperands(ref))
    }

    func operand(at index: UInt32) -> Value? {
        guard let ref = LLVMGetOperand(ref, index) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }

    func replaceAllUsesWith(_ newValue: Value) {
        LLVMReplaceAllUsesWith(ref, newValue.ref)
    }

    var uses: [Value] {
        var result: [Value] = []
        guard let first = LLVMGetFirstUse(ref) else { return [] }
        var current: LLVMUseRef? = first
        while let use = current {
            if let user = LLVMGetUser(use) {
                result.append(Value(ref: user, context: context, module: module))
            }
            current = LLVMGetNextUse(use)
        }
        return result
    }

    var useCount: UInt32 {
        var count: UInt32 = 0
        var current: LLVMUseRef? = LLVMGetFirstUse(ref)
        while let use = current {
            count += 1
            current = LLVMGetNextUse(use)
        }
        return count
    }

    func operandUser(at index: UInt32) -> Value? {
        guard let useRef = LLVMGetOperandUse(ref, index) else { return nil }
        guard let user = LLVMGetUser(useRef) else { return nil }
        return Value(ref: user, context: context, module: module)
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
