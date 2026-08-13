import cLLVM

public final class DbgRecord {
    public let ref: LLVMDbgRecordRef
    public let context: Context
    public let module: Module?

    public init(ref: LLVMDbgRecordRef, context: Context, module: Module?) {
        self.ref = ref
        self.context = context
        self.module = module
    }

    public var kind: LLVMDbgRecordKind {
        LLVMDbgRecordGetKind(ref)
    }

    public var kindName: String {
        switch kind {
        case LLVMDbgRecordLabel: "label"
        case LLVMDbgRecordDeclare: "declare"
        case LLVMDbgRecordValue: "value"
        case LLVMDbgRecordAssign: "assign"
        default: "unknown"
        }
    }

    public var debugLoc: Metadata? {
        guard let loc = LLVMDbgRecordGetDebugLoc(ref) else { return nil }
        return Metadata(ref: loc)
    }

    public var description: String {
        let ptr = LLVMPrintDbgRecordToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public var variable: Metadata? {
        guard kind == LLVMDbgRecordDeclare || kind == LLVMDbgRecordValue || kind == LLVMDbgRecordAssign else {
            return nil
        }
        guard let varRef = LLVMDbgVariableRecordGetVariable(ref) else { return nil }
        return Metadata(ref: varRef)
    }

    public var expression: Metadata? {
        guard let expr = LLVMDbgVariableRecordGetExpression(ref) else { return nil }
        return Metadata(ref: expr)
    }

    public func value(at index: UInt32) -> Value? {
        guard let ref = LLVMDbgVariableRecordGetValue(ref, index) else { return nil }
        return Value(ref: ref, context: context, module: module)
    }
}
