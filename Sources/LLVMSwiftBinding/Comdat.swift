import cLLVM

final class Comdat {
    let ref: LLVMComdatRef

    init(ref: LLVMComdatRef) {
        self.ref = ref
    }

    var selectionKind: LLVMComdatSelectionKind {
        get { LLVMGetComdatSelectionKind(ref) }
        set { LLVMSetComdatSelectionKind(ref, newValue) }
    }
}

extension Module {
    func getOrInsertComdat(_ name: String) -> Comdat {
        let ref = name.withCString { namePtr in
            LLVMGetOrInsertComdat(self.ref, namePtr)
        }
        return Comdat(ref: ref!)
    }
}

extension Value {
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
