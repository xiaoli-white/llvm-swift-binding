import cLLVM

public final class Comdat {
    public let ref: LLVMComdatRef

    public init(ref: LLVMComdatRef) {
        self.ref = ref
    }

    public var selectionKind: ComdatSelectionKind {
        get { ComdatSelectionKind(llvm: LLVMGetComdatSelectionKind(ref))! }
        set { LLVMSetComdatSelectionKind(ref, newValue.llvm) }
    }
}

public extension Module {
    func getOrInsertComdat(_ name: String) -> Comdat {
        let ref = name.withCString { namePtr in
            LLVMGetOrInsertComdat(self.ref, namePtr)
        }
        return Comdat(ref: ref!)
    }
}

public extension Value {
    var comdat: Comdat? {
        get {
            guard let ref = LLVMGetComdat(ref) else { return nil }
            return Comdat(ref: ref)
        }
        set {
            LLVMSetComdat(ref, newValue?.ref)
        }
    }
}
