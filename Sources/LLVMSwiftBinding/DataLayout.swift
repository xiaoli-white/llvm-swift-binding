import cLLVM

public final class DataLayout {
    public let ref: LLVMTargetDataRef
    private var owns: Bool

    public init(string: String) {
        let ref = string.withCString { stringPtr in
            LLVMCreateTargetData(stringPtr)
        }
        self.ref = ref!
        owns = true
    }

    public init(ref: LLVMTargetDataRef, owns: Bool) {
        self.ref = ref
        self.owns = owns
    }

    deinit {
        if owns {
            LLVMDisposeTargetData(ref)
        }
    }

    public var string: String {
        let ptr = LLVMCopyStringRepOfTargetData(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public var byteOrder: LLVMByteOrdering {
        LLVMByteOrder(ref)
    }

    public var pointerSize: UInt32 {
        LLVMPointerSize(ref)
    }

    public func pointerSize(addressSpace: UInt32) -> UInt32 {
        LLVMPointerSizeForAS(ref, addressSpace)
    }

    public func intPtrType(in context: Context) -> LLVMType {
        context.wrapType(LLVMIntPtrTypeInContext(context.ref, ref)!)
    }

    public func intPtrType(addressSpace: UInt32, in context: Context) -> LLVMType {
        context.wrapType(LLVMIntPtrTypeForASInContext(context.ref, ref, addressSpace)!)
    }

    public func sizeOfTypeInBits(_ type: LLVMType) -> UInt64 {
        LLVMSizeOfTypeInBits(ref, type.ref)
    }

    public func storeSizeOfType(_ type: LLVMType) -> UInt64 {
        LLVMStoreSizeOfType(ref, type.ref)
    }

    public func abiSizeOfType(_ type: LLVMType) -> UInt64 {
        LLVMABISizeOfType(ref, type.ref)
    }

    public func abiAlignmentOfType(_ type: LLVMType) -> UInt32 {
        LLVMABIAlignmentOfType(ref, type.ref)
    }

    public func callFrameAlignmentOfType(_ type: LLVMType) -> UInt32 {
        LLVMCallFrameAlignmentOfType(ref, type.ref)
    }

    public func preferredAlignmentOfType(_ type: LLVMType) -> UInt32 {
        LLVMPreferredAlignmentOfType(ref, type.ref)
    }

    public func preferredAlignmentOfGlobal(_ global: GlobalVariable) -> UInt32 {
        LLVMPreferredAlignmentOfGlobal(ref, global.ref)
    }

    public func element(atOffset offset: UInt64, in structType: StructType) -> UInt32 {
        LLVMElementAtOffset(ref, structType.ref, offset)
    }

    public func offsetOfElement(_ index: UInt32, in structType: StructType) -> UInt64 {
        LLVMOffsetOfElement(ref, structType.ref, index)
    }
}

public extension Module {
    var dataLayout: DataLayout {
        get {
            DataLayout(ref: LLVMGetModuleDataLayout(ref), owns: false)
        }
        set {
            LLVMSetModuleDataLayout(ref, newValue.ref)
        }
    }
}

public extension TargetMachine {
    var dataLayout: DataLayout {
        DataLayout(ref: LLVMCreateTargetDataLayout(ref), owns: true)
    }
}
