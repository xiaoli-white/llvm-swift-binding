import cLLVM

class Constant: Value {
    init(ref: LLVMValueRef, context: Context) {
        super.init(ref: ref, context: context, module: nil)
    }

    func aggregateElement(at index: UInt32) -> Constant? {
        guard let ref = LLVMGetAggregateElement(ref, index) else { return nil }
        return context.wrapConstant(ref)
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
        var losesInfo: LLVMBool = 0
        return LLVMConstRealGetDouble(ref, &losesInfo)
    }
}

final class UndefValue: Constant {}

final class PoisonValue: Constant {}

final class ConstantTokenNone: Constant {}

final class ConstantArray: Constant {}

final class ConstantStruct: Constant {}

final class ConstantDataArray: Constant {
    var isConstantString: Bool {
        LLVMIsConstantString(ref) != 0
    }

    var stringValue: String? {
        guard isConstantString else { return nil }
        var length: Int = 0
        guard let ptr = LLVMGetAsString(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    var rawData: [UInt8] {
        var size: Int = 0
        guard let ptr = LLVMGetRawDataValues(ref, &size) else { return [] }
        return UnsafeBufferPointer(start: ptr, count: size).map { UInt8(bitPattern: $0) }
    }
}

final class ConstantExpr: Constant {}

final class ConstantVector: Constant {}

final class BlockAddress: Constant {
    var function: Function? {
        guard let fnRef = LLVMGetBlockAddressFunction(ref) else { return nil }
        guard let moduleRef = LLVMGetGlobalParent(fnRef) else { return nil }
        let module = Module(ref: moduleRef, context: context)
        module.ownsRef = false
        return Function(ref: fnRef, module: module)
    }

    var basicBlock: BasicBlock? {
        guard let block = LLVMGetBlockAddressBasicBlock(ref) else { return nil }
        guard let function = function else { return nil }
        return BasicBlock(ref: block, function: function, module: function.module!)
    }
}
