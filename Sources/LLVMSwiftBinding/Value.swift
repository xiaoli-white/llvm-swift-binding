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

    public var type: LLVMType {
        context.wrapType(LLVMTypeOf(ref))
    }

    public var name: String {
        get { String(cString: LLVMGetValueName(ref)) }
        set { LLVMSetValueName(ref, newValue) }
    }

    public var nameWithLength: String {
        var length = 0
        guard let ptr = LLVMGetValueName2(ref, &length) else { return "" }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var shortName: String {
        var length = 0
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

    public var visibility: Visibility {
        get { Visibility(llvm: LLVMGetVisibility(ref))! }
        set { LLVMSetVisibility(ref, newValue.llvm) }
    }

    public var dllStorageClass: DLLStorageClass {
        get { DLLStorageClass(llvm: LLVMGetDLLStorageClass(ref))! }
        set { LLVMSetDLLStorageClass(ref, newValue.llvm) }
    }

    public var description: String {
        let ptr = LLVMPrintValueToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public var valueKind: ValueKind {
        ValueKind(llvm: LLVMGetValueKind(ref))!
    }

    public var kindName: String {
        switch valueKind {
        case .Argument: "argument"
        case .BasicBlock: "basic-block"
        case .MemoryUse: "memory-use"
        case .MemoryDef: "memory-def"
        case .MemoryPhi: "memory-phi"
        case .Function: "function"
        case .GlobalAlias: "global-alias"
        case .GlobalIFunc: "global-ifunc"
        case .GlobalVariable: "global-variable"
        case .BlockAddress: "block-address"
        case .ConstantExpr: "constant-expr"
        case .ConstantArray: "constant-array"
        case .ConstantStruct: "constant-struct"
        case .ConstantVector: "constant-vector"
        case .UndefValue: "undef"
        case .ConstantAggregateZero: "constant-aggregate-zero"
        case .ConstantDataArray: "constant-data-array"
        case .ConstantDataVector: "constant-data-vector"
        case .ConstantInt: "constant-int"
        case .ConstantFP: "constant-fp"
        case .ConstantPointerNull: "constant-pointer-null"
        case .ConstantTokenNone: "constant-token-none"
        case .MetadataAsValue: "metadata-as-value"
        case .InlineAsm: "inline-asm"
        case .Instruction: "instruction"
        case .PoisonValue: "poison"
        case .ConstantTargetNone: "constant-target-none"
        case .ConstantPtrAuth: "constant-ptr-auth"
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

    public func setOperand(at index: UInt32, _ value: Value) {
        LLVMSetOperand(ref, index, value.ref)
    }

    public var isBasicBlock: Bool {
        LLVMValueIsBasicBlock(ref) != 0
    }

    public var asBasicBlock: BasicBlock? {
        guard isBasicBlock else { return nil }
        let block = LLVMValueAsBasicBlock(ref)!
        guard let fnRef = LLVMGetBasicBlockParent(block) else { return nil }
        let resultModule: Module
        if let selfModule = module {
            resultModule = selfModule
        } else {
            resultModule = Module(ref: LLVMGetGlobalParent(fnRef)!, context: context)
            resultModule.ownsRef = false
        }
        let function = Function(ref: fnRef, module: resultModule)
        return BasicBlock(ref: block, function: function, module: resultModule)
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

    public func setAlignment(_ alignment: UInt32) {
        LLVMSetParamAlignment(ref, alignment)
    }
}

public final class InlineAsm: Value {
    public var asmString: String? {
        var length = 0
        guard let ptr = LLVMGetInlineAsmAsmString(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var constraintString: String? {
        var length = 0
        guard let ptr = LLVMGetInlineAsmConstraintString(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var dialect: InlineAsmDialect {
        InlineAsmDialect(llvm: LLVMGetInlineAsmDialect(ref))!
    }

    public var hasSideEffects: Bool {
        LLVMGetInlineAsmHasSideEffects(ref) != 0
    }

    public var needsAlignedStack: Bool {
        LLVMGetInlineAsmNeedsAlignedStack(ref) != 0
    }

    public var canUnwind: Bool {
        LLVMGetInlineAsmCanUnwind(ref) != 0
    }

    public var functionType: LLVMType {
        context.wrapType(LLVMGetInlineAsmFunctionType(ref)!)
    }
}
