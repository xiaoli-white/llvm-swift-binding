import cLLVM

final class DataLayout {
    let ref: LLVMTargetDataRef
    private var owns: Bool

    init(string: String) {
        let ref = string.withCString { stringPtr in
            LLVMCreateTargetData(stringPtr)
        }
        self.ref = ref!
        self.owns = true
    }

    init(ref: LLVMTargetDataRef, owns: Bool) {
        self.ref = ref
        self.owns = owns
    }

    deinit {
        if owns {
            LLVMDisposeTargetData(ref)
        }
    }

    var string: String {
        let ptr = LLVMCopyStringRepOfTargetData(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    var byteOrder: LLVMByteOrdering {
        LLVMByteOrder(ref)
    }

    var pointerSize: UInt32 {
        LLVMPointerSize(ref)
    }

    func pointerSize(addressSpace: UInt32) -> UInt32 {
        LLVMPointerSizeForAS(ref, addressSpace)
    }

    func intPtrType(in context: Context) -> Type {
        context.wrapType(LLVMIntPtrTypeInContext(context.ref, ref)!)
    }

    func intPtrType(addressSpace: UInt32, in context: Context) -> Type {
        context.wrapType(LLVMIntPtrTypeForASInContext(context.ref, ref, addressSpace)!)
    }

    func sizeOfTypeInBits(_ type: Type) -> UInt64 {
        LLVMSizeOfTypeInBits(ref, type.ref)
    }

    func storeSizeOfType(_ type: Type) -> UInt64 {
        LLVMStoreSizeOfType(ref, type.ref)
    }

    func abiSizeOfType(_ type: Type) -> UInt64 {
        LLVMABISizeOfType(ref, type.ref)
    }

    func abiAlignmentOfType(_ type: Type) -> UInt32 {
        LLVMABIAlignmentOfType(ref, type.ref)
    }

    func callFrameAlignmentOfType(_ type: Type) -> UInt32 {
        LLVMCallFrameAlignmentOfType(ref, type.ref)
    }

    func preferredAlignmentOfType(_ type: Type) -> UInt32 {
        LLVMPreferredAlignmentOfType(ref, type.ref)
    }

    func preferredAlignmentOfGlobal(_ global: GlobalVariable) -> UInt32 {
        LLVMPreferredAlignmentOfGlobal(ref, global.ref)
    }

    func element(atOffset offset: UInt64, in structType: StructType) -> UInt32 {
        LLVMElementAtOffset(ref, structType.ref, offset)
    }

    func offsetOfElement(_ index: UInt32, in structType: StructType) -> UInt64 {
        LLVMOffsetOfElement(ref, structType.ref, index)
    }
}

extension Module {
    var dataLayout: DataLayout {
        get {
            DataLayout(ref: LLVMGetModuleDataLayout(ref), owns: false)
        }
        set {
            LLVMSetModuleDataLayout(ref, newValue.ref)
        }
    }
}

extension TargetMachine {
    var dataLayout: DataLayout {
        DataLayout(ref: LLVMCreateTargetDataLayout(ref), owns: true)
    }
}
