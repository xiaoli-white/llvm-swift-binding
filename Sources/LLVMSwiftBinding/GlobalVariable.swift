import cLLVM

final class GlobalVariable: Value {
    init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    var initializer: Constant? {
        get {
            guard let val = LLVMGetInitializer(ref) else { return nil }
            return context.wrapConstant(val)
        }
        set {
            LLVMSetInitializer(ref, newValue?.ref)
        }
    }

    override var isConstant: Bool {
        LLVMIsGlobalConstant(ref) != 0
    }

    var isThreadLocal: Bool {
        get { LLVMIsThreadLocal(ref) != 0 }
        set { LLVMSetThreadLocal(ref, newValue ? 1 : 0) }
    }

    var isGlobalConstant: Bool {
        get { isConstant }
        set { LLVMSetGlobalConstant(ref, newValue ? 1 : 0) }
    }

    var tlsModel: LLVMThreadLocalMode {
        get { LLVMGetThreadLocalMode(ref) }
        set { LLVMSetThreadLocalMode(ref, newValue) }
    }

    var section: String {
        get {
            guard let ptr = LLVMGetSection(ref) else { return "" }
            return String(cString: ptr)
        }
        set { LLVMSetSection(ref, newValue) }
    }

    var unnamedAddress: LLVMUnnamedAddr {
        get { LLVMGetUnnamedAddress(ref) }
        set { LLVMSetUnnamedAddress(ref, newValue) }
    }

    var linkage: LLVMLinkage {
        get { LLVMGetLinkage(ref) }
        set { LLVMSetLinkage(ref, newValue) }
    }

    var alignment: UInt32 {
        get { LLVMGetAlignment(ref) }
        set { LLVMSetAlignment(ref, newValue) }
    }

    var parentModule: Module {
        let moduleRef = LLVMGetGlobalParent(ref)!
        let module = Module(ref: moduleRef, context: context)
        module.ownsRef = false
        return module
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
