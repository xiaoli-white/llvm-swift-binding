import cLLVM

public class Constant: Value {
    public init(ref: LLVMValueRef, context: Context) {
        super.init(ref: ref, context: context, module: nil)
    }

    public func aggregateElement(at index: UInt32) -> Constant? {
        guard let ref = LLVMGetAggregateElement(ref, index) else { return nil }
        return context.wrapConstant(ref)
    }
}

public final class ConstantInt: Constant {
    public var unsignedValue: UInt64 {
        LLVMConstIntGetZExtValue(ref)
    }

    public var signedValue: Int64 {
        LLVMConstIntGetSExtValue(ref)
    }
}

public final class ConstantFP: Constant {
    public var doubleValue: Double {
        var losesInfo: LLVMBool = 0
        return LLVMConstRealGetDouble(ref, &losesInfo)
    }

    public var doubleValueWithStatus: (value: Double, isFinite: Bool) {
        var losesInfo: LLVMBool = 0
        let value = LLVMConstRealGetDouble(ref, &losesInfo)
        return (value, losesInfo == 0)
    }
}

public final class UndefValue: Constant {}

public final class PoisonValue: Constant {}

public final class ConstantTokenNone: Constant {}

public final class ConstantAggregateZero: Constant {}

public final class ConstantArray: Constant {}

public final class ConstantStruct: Constant {}

public final class ConstantDataArray: Constant {
    public var isConstantString: Bool {
        LLVMIsConstantString(ref) != 0
    }

    public var stringValue: String? {
        guard isConstantString else { return nil }
        var length = 0
        guard let ptr = LLVMGetAsString(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var rawData: [UInt8] {
        var size = 0
        guard let ptr = LLVMGetRawDataValues(ref, &size) else { return [] }
        return UnsafeBufferPointer(start: ptr, count: size).map { UInt8(bitPattern: $0) }
    }
}

public final class ConstantExpr: Constant {
    public var opcode: Opcode {
        Opcode(llvm: LLVMGetConstOpcode(ref))!
    }

    public var numIndices: UInt32 {
        LLVMGetNumIndices(ref)
    }

    public var indices: [UInt32] {
        guard let ptr = LLVMGetIndices(ref) else { return [] }
        return Array(UnsafeBufferPointer(start: ptr, count: Int(numIndices)))
    }
}

public final class ConstantVector: Constant {}

public final class BlockAddress: Constant {
    public var function: Function? {
        guard let fnRef = LLVMGetBlockAddressFunction(ref) else { return nil }
        guard let moduleRef = LLVMGetGlobalParent(fnRef) else { return nil }
        let module = Module(ref: moduleRef, context: context)
        module.ownsRef = false
        return Function(ref: fnRef, module: module)
    }

    public var basicBlock: BasicBlock? {
        guard let block = LLVMGetBlockAddressBasicBlock(ref) else { return nil }
        guard let function else { return nil }
        return BasicBlock(ref: block, function: function, module: function.module!)
    }
}
