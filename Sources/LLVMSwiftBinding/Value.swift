import cLLVM

public class Value {
    public let ref: LLVMValueRef
    public let context: Context
    public let module: Module?

    public init(ref: LLVMValueRef, context: Context, module: Module? = nil) {
        self.ref = ref
        self.context = context
        self.module = module
    }

    public var type: Type {
        context.wrapType(LLVMTypeOf(ref))
    }

    public var name: String {
        get { String(cString: LLVMGetValueName(ref)) }
        set { LLVMSetValueName(ref, newValue) }
    }

    public var nameWithLength: String {
        var length: Int = 0
        guard let ptr = LLVMGetValueName2(ref, &length) else { return "" }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var shortName: String {
        var length: Int = 0
        guard let ptr = LLVMGetValueName2(ref, &length) else { return "" }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        let name = String(decoding: bytes, as: UTF8.self)
        return name.hasPrefix("%") ? String(name.dropFirst()) : name
    }

    public var hasMetadata: Bool {
        LLVMHasMetadata(ref) != 0
    }

    public var isConstant: Bool {
        LLVMIsConstant(ref) != 0
    }

    public var isUndef: Bool {
        LLVMIsUndef(ref) != 0
    }

    public var isNull: Bool {
        LLVMIsNull(ref) != 0
    }

    public var isPoison: Bool {
        LLVMIsPoison(ref) != 0
    }

    public var isDeclaration: Bool {
        LLVMIsDeclaration(ref) != 0
    }

    public var visibility: LLVMVisibility {
        get { LLVMGetVisibility(ref) }
        set { LLVMSetVisibility(ref, newValue) }
    }

    public var dllStorageClass: LLVMDLLStorageClass {
        get { LLVMGetDLLStorageClass(ref) }
        set { LLVMSetDLLStorageClass(ref, newValue) }
    }

    public var description: String {
        let ptr = LLVMPrintValueToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public var valueKind: LLVMValueKind {
        LLVMGetValueKind(ref)
    }

    public var kindName: String {
        switch valueKind {
        case LLVMArgumentValueKind: return "argument"
        case LLVMBasicBlockValueKind: return "basic-block"
        case LLVMMemoryUseValueKind: return "memory-use"
        case LLVMMemoryDefValueKind: return "memory-def"
        case LLVMMemoryPhiValueKind: return "memory-phi"
        case LLVMFunctionValueKind: return "function"
        case LLVMGlobalAliasValueKind: return "global-alias"
        case LLVMGlobalIFuncValueKind: return "global-ifunc"
        case LLVMGlobalVariableValueKind: return "global-variable"
        case LLVMBlockAddressValueKind: return "block-address"
        case LLVMConstantExprValueKind: return "constant-expr"
        case LLVMConstantArrayValueKind: return "constant-array"
        case LLVMConstantStructValueKind: return "constant-struct"
        case LLVMConstantVectorValueKind: return "constant-vector"
        case LLVMUndefValueValueKind: return "undef"
        case LLVMConstantAggregateZeroValueKind: return "constant-aggregate-zero"
        case LLVMConstantDataArrayValueKind: return "constant-data-array"
        case LLVMConstantDataVectorValueKind: return "constant-data-vector"
        case LLVMConstantIntValueKind: return "constant-int"
        case LLVMConstantFPValueKind: return "constant-fp"
        case LLVMConstantPointerNullValueKind: return "constant-pointer-null"
        case LLVMConstantTokenNoneValueKind: return "constant-token-none"
        case LLVMMetadataAsValueValueKind: return "metadata-as-value"
        case LLVMInlineAsmValueKind: return "inline-asm"
        case LLVMInstructionValueKind: return "instruction"
        case LLVMPoisonValueValueKind: return "poison"
        case LLVMConstantTargetNoneValueKind: return "constant-target-none"
        default: return "unknown"
        }
    }

    public var numOperands: UInt32 {
        UInt32(LLVMGetNumOperands(ref))
    }

    public func operand(at index: UInt32) -> Value? {
        guard let ref = LLVMGetOperand(ref, index) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }

    public func replaceAllUsesWith(_ newValue: Value) {
        LLVMReplaceAllUsesWith(ref, newValue.ref)
    }

    public var uses: [Value] {
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

    public var useCount: UInt32 {
        var count: UInt32 = 0
        var current: LLVMUseRef? = LLVMGetFirstUse(ref)
        while let use = current {
            count += 1
            current = LLVMGetNextUse(use)
        }
        return count
    }

    public func operandUser(at index: UInt32) -> Value? {
        guard let useRef = LLVMGetOperandUse(ref, index) else { return nil }
        guard let user = LLVMGetUser(useRef) else { return nil }
        return Value(ref: user, context: context, module: module)
    }

    public func setMetadata(kind: UInt32, _ node: Value?) {
        LLVMSetMetadata(ref, kind, node?.ref)
    }

    public func getMetadata(kind: UInt32) -> Value? {
        guard let ref = LLVMGetMetadata(ref, kind) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }
}

public final class Argument: Value {
    public init(ref: LLVMValueRef, function: Function, module: Module) {
        super.init(ref: ref, context: function.context, module: module)
    }
}
