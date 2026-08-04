import cLLVM

final class GlobalVariable: Value {
    init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    var initializer: Value? {
        get {
            guard let val = LLVMGetInitializer(ref) else { return nil }
            return Value(ref: val, context: context, module: module)
        }
        set {
            LLVMSetInitializer(ref, newValue?.ref)
        }
    }

    var isConstant: Bool {
        LLVMIsGlobalConstant(ref) != 0
    }

    var isThreadLocal: Bool {
        LLVMIsThreadLocal(ref) != 0
    }

    var linkage: LLVMLinkage {
        get { LLVMGetLinkage(ref) }
        set { LLVMSetLinkage(ref, newValue) }
    }

    var alignment: UInt32 {
        get { LLVMGetAlignment(ref) }
        set { LLVMSetAlignment(ref, newValue) }
    }

    func addDebugInfo(_ gve: Metadata) {
        LLVMGlobalAddDebugInfo(ref, gve.ref)
    }

    func setMetadata(kind: UInt32, _ metadata: Metadata?) {
        LLVMGlobalSetMetadata(ref, kind, metadata?.ref)
    }

    func addMetadata(kind: UInt32, _ metadata: Metadata) {
        LLVMGlobalAddMetadata(ref, kind, metadata.ref)
    }

    func eraseMetadata(kind: UInt32) {
        LLVMGlobalEraseMetadata(ref, kind)
    }

    func clearMetadata() {
        LLVMGlobalClearMetadata(ref)
    }
}
