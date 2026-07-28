import cLLVM

class Constant: Value {
    init(ref: LLVMValueRef, context: Context) {
        super.init(ref: ref, context: context, module: nil)
    }
}

final class ConstantInt: Constant {
    var unsignedValue: UInt64 {
        LLVMConstIntGetZExtValue(ref)
    }

    var signedValue: Int64 {
        LLVMConstIntGetSExtValue(ref)
    }
}

final class ConstantFP: Constant {
    var doubleValue: Double {
        LLVMConstRealGetDouble(ref, nil)
    }
}
