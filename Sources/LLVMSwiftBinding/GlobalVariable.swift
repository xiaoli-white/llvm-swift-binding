import cLLVM

public final class GlobalVariable: Value {
    public init(ref: LLVMValueRef, module: Module) {
        super.init(ref: ref, context: module.context, module: module)
    }

    public var valueType: LLVMType {
        context.wrapType(LLVMGlobalGetValueType(ref))
    }

    public var initializer: Constant? {
        get {
            guard let val = LLVMGetInitializer(ref) else { return nil }
            return context.wrapConstant(val)
        }
        set {
            LLVMSetInitializer(ref, newValue?.ref)
        }
    }

    public override var isConstant: Bool {
        LLVMIsGlobalConstant(ref) != 0
    }

    public var isThreadLocal: Bool {
        get { LLVMIsThreadLocal(ref) != 0 }
        set { LLVMSetThreadLocal(ref, newValue ? 1 : 0) }
    }

    public var isGlobalConstant: Bool {
        get { isConstant }
        set { LLVMSetGlobalConstant(ref, newValue ? 1 : 0) }
    }

    public var tlsModel: ThreadLocalMode {
        get { ThreadLocalMode(llvm: LLVMGetThreadLocalMode(ref))! }
        set { LLVMSetThreadLocalMode(ref, newValue.llvm) }
    }

    public var section: String {
        get {
            guard let ptr = LLVMGetSection(ref) else { return "" }
            return String(cString: ptr)
        }
        set { LLVMSetSection(ref, newValue) }
    }

    public var unnamedAddress: UnnamedAddr {
        get { UnnamedAddr(llvm: LLVMGetUnnamedAddress(ref))! }
        set { LLVMSetUnnamedAddress(ref, newValue.llvm) }
    }

    public var linkage: Linkage {
        get { Linkage(llvm: LLVMGetLinkage(ref))! }
        set { LLVMSetLinkage(ref, newValue.llvm) }
    }

    public var alignment: UInt32 {
        get { LLVMGetAlignment(ref) }
        set { LLVMSetAlignment(ref, newValue) }
    }

    public var isExternallyInitialized: Bool {
        get { LLVMIsExternallyInitialized(ref) != 0 }
        set { LLVMSetExternallyInitialized(ref, newValue ? 1 : 0) }
    }

    public func eraseFromParent() {
        LLVMDeleteGlobal(ref)
    }

    public var parentModule: Module {
        let moduleRef = LLVMGetGlobalParent(ref)!
        let module = Module(ref: moduleRef, context: context)
        module.ownsRef = false
        return module
    }

    public func addDebugInfo(_ gve: Metadata) {
        LLVMGlobalAddDebugInfo(ref, gve.ref)
    }

    public func setMetadata(kind: UInt32, _ metadata: Metadata?) {
        LLVMGlobalSetMetadata(ref, kind, metadata?.ref)
    }

    public func addMetadata(kind: UInt32, _ metadata: Metadata) {
        LLVMGlobalAddMetadata(ref, kind, metadata.ref)
    }

    public func eraseMetadata(kind: UInt32) {
        LLVMGlobalEraseMetadata(ref, kind)
    }

    public func clearMetadata() {
        LLVMGlobalClearMetadata(ref)
    }
}
