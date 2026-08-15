import cLLVM

public class LLVMType {
    public let ref: LLVMTypeRef
    public let context: Context

    public init(ref: LLVMTypeRef, context: Context) {
        self.ref = ref
        self.context = context
    }

    public var kind: TypeKind {
        TypeKind(llvm: LLVMGetTypeKind(ref))!
    }

    public var isVoid: Bool {
        kind == .Void
    }

    public var isInteger: Bool {
        kind == .Integer
    }

    public var isFloat: Bool {
        switch kind {
        case .Half, .Float, .Double, .X86FP80, .FP128, .PPCFP128, .BFloat:
            true
        default:
            false
        }
    }

    public var isFunction: Bool {
        kind == .Function
    }

    public var isStruct: Bool {
        kind == .Struct
    }

    public var isArray: Bool {
        kind == .Array
    }

    public var isPointer: Bool {
        kind == .Pointer
    }

    public var isVector: Bool {
        kind == .Vector || kind == .ScalableVector
    }

    public var isTargetExt: Bool {
        kind == .TargetExt
    }

    public var contextRef: LLVMContextRef {
        LLVMGetTypeContext(ref)
    }

    public var isSized: Bool {
        LLVMTypeIsSized(ref) != 0
    }

    public var numContainedTypes: UInt32 {
        UInt32(LLVMGetNumContainedTypes(ref))
    }

    public var containedTypes: [LLVMType] {
        let count = Int(numContainedTypes)
        guard count > 0 else { return [] }
        var refs = [LLVMTypeRef?](repeating: nil, count: count)
        refs.withUnsafeMutableBufferPointer { buffer in
            LLVMGetSubtypes(ref, buffer.baseAddress)
        }
        return refs.map { context.wrapType($0!) }
    }

    public var description: String {
        let ptr = LLVMPrintTypeToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }
}

public final class VoidType: LLVMType {}

public final class IntegerType: LLVMType {
    public var width: UInt32 {
        LLVMGetIntTypeWidth(ref)
    }
}

public final class FloatType: LLVMType {}

public final class FunctionType: LLVMType {
    public var returnType: LLVMType {
        context.wrapType(LLVMGetReturnType(ref)!)
    }

    public var parameterCount: UInt32 {
        LLVMCountParamTypes(ref)
    }

    public var parameterTypes: [LLVMType] {
        let count = Int(parameterCount)
        guard count > 0 else { return [] }
        var types = [LLVMTypeRef?](repeating: nil, count: count)
        types.withUnsafeMutableBufferPointer { buffer in
            LLVMGetParamTypes(ref, buffer.baseAddress)
        }
        return types.map { context.wrapType($0!) }
    }

    public var isVariadic: Bool {
        LLVMIsFunctionVarArg(ref) != 0
    }
}

public final class PointerType: LLVMType {
    public var elementType: LLVMType {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    public var addressSpace: UInt32 {
        LLVMGetPointerAddressSpace(ref)
    }
}

public final class StructType: LLVMType {
    public var elementCount: UInt32 {
        LLVMCountStructElementTypes(ref)
    }

    public var elementTypes: [LLVMType] {
        let count = Int(elementCount)
        guard count > 0 else { return [] }
        var types = [LLVMTypeRef?](repeating: nil, count: count)
        types.withUnsafeMutableBufferPointer { buffer in
            LLVMGetStructElementTypes(ref, buffer.baseAddress)
        }
        return types.map { context.wrapType($0!) }
    }

    public func elementType(at index: UInt32) -> LLVMType {
        context.wrapType(LLVMStructGetTypeAtIndex(ref, index)!)
    }

    public var isPacked: Bool {
        LLVMIsPackedStruct(ref) != 0
    }

    public var isOpaque: Bool {
        LLVMIsOpaqueStruct(ref) != 0
    }

    public var isLiteral: Bool {
        LLVMIsLiteralStruct(ref) != 0
    }

    public var name: String? {
        guard let ptr = LLVMGetStructName(ref) else { return nil }
        return String(cString: ptr)
    }
}

public final class ArrayType: LLVMType {
    public var elementType: LLVMType {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    public var elementCount: UInt64 {
        LLVMGetArrayLength2(ref)
    }
}

public final class VectorType: LLVMType {
    public var elementType: LLVMType {
        context.wrapType(LLVMGetElementType(ref)!)
    }

    public var elementCount: UInt32 {
        LLVMGetVectorSize(ref)
    }

    public var isScalable: Bool {
        kind == .ScalableVector
    }
}

public final class LabelType: LLVMType {}
public final class TokenType: LLVMType {}
public final class MetadataType: LLVMType {}

public final class TargetExtType: LLVMType {
    public var name: String? {
        guard let ptr = LLVMGetTargetExtTypeName(ref) else { return nil }
        return String(cString: ptr)
    }

    public var typeParameterCount: UInt32 {
        LLVMGetTargetExtTypeNumTypeParams(ref)
    }

    public func typeParameter(at index: UInt32) -> LLVMType {
        context.wrapType(LLVMGetTargetExtTypeTypeParam(ref, index)!)
    }

    public var intParameterCount: UInt32 {
        LLVMGetTargetExtTypeNumIntParams(ref)
    }

    public func intParameter(at index: UInt32) -> UInt32 {
        LLVMGetTargetExtTypeIntParam(ref, index)
    }
}
