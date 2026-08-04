import cLLVM

final class Context {
    let ref: LLVMContextRef
    private var typeCache: [OpaquePointer: Type] = [:]
    private var constantCache: [OpaquePointer: Constant] = [:]

    init() {
        self.ref = LLVMContextCreate()
    }

    deinit {
        LLVMContextDispose(ref)
    }

    var int1: IntegerType { intType(width: 1) }
    var int8: IntegerType { intType(width: 8) }
    var int16: IntegerType { intType(width: 16) }
    var int32: IntegerType { intType(width: 32) }
    var int64: IntegerType { intType(width: 64) }
    var int128: IntegerType { intType(width: 128) }

    func intType(width: UInt32) -> IntegerType {
        wrapType(LLVMIntTypeInContext(ref, width)!) as! IntegerType
    }

    var void: VoidType {
        wrapType(LLVMVoidTypeInContext(ref)!) as! VoidType
    }

    var float: FloatType {
        wrapType(LLVMFloatTypeInContext(ref)!) as! FloatType
    }

    var double: FloatType {
        wrapType(LLVMDoubleTypeInContext(ref)!) as! FloatType
    }

    func functionType(returnType: Type, parameterTypes: [Type] = [], isVariadic: Bool = false) -> FunctionType {
        var params: [LLVMTypeRef?] = parameterTypes.map { $0.ref }
        let ref = params.withUnsafeMutableBufferPointer { buffer in
            LLVMFunctionType(returnType.ref, buffer.baseAddress, UInt32(parameterTypes.count), isVariadic ? 1 : 0)
        }
        return wrapType(ref!) as! FunctionType
    }

    func constantInt(_ value: UInt64, type: IntegerType) -> ConstantInt {
        let ref = LLVMConstInt(type.ref, value, 0)!
        return wrapConstant(ref) as! ConstantInt
    }

    func constantInt(signed value: Int64, type: IntegerType) -> ConstantInt {
        let ref = LLVMConstInt(type.ref, UInt64(bitPattern: value), 1)!
        return wrapConstant(ref) as! ConstantInt
    }

    func constantFP(_ value: Double, type: FloatType) -> ConstantFP {
        let ref = LLVMConstReal(type.ref, value)!
        return wrapConstant(ref) as! ConstantFP
    }

    func pointerType(addressSpace: UInt32 = 0) -> PointerType {
        let ref = LLVMPointerTypeInContext(self.ref, addressSpace)
        return wrapType(ref!) as! PointerType
    }

    func constantNull(_ type: Type) -> Constant {
        let ref = LLVMConstNull(type.ref)!
        return wrapConstant(ref)
    }

    func undef(_ type: Type) -> UndefValue {
        let ref = LLVMGetUndef(type.ref)!
        return UndefValue(ref: ref, context: self)
    }

    func constantArray(_ values: [Constant], elementType: Type) -> ConstantArray {
        var valRefs: [LLVMValueRef?] = values.map { $0.ref }
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstArray2(elementType.ref, buffer.baseAddress, UInt64(values.count))
        }
        return ConstantArray(ref: ref!, context: self)
    }

    func constantStruct(_ values: [Constant], isPacked: Bool = false) -> ConstantStruct {
        var valRefs: [LLVMValueRef?] = values.map { $0.ref }
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstStructInContext(self.ref, buffer.baseAddress, UInt32(values.count), isPacked ? 1 : 0)
        }
        return ConstantStruct(ref: ref!, context: self)
    }

    func structType(elementTypes: [Type], isPacked: Bool = false) -> StructType {
        var members: [LLVMTypeRef?] = elementTypes.map { $0.ref }
        let ref = members.withUnsafeMutableBufferPointer { buffer in
            LLVMStructTypeInContext(self.ref, buffer.baseAddress, UInt32(elementTypes.count), isPacked ? 1 : 0)
        }
        return wrapType(ref!) as! StructType
    }

    func arrayType(elementType: Type, count: UInt32) -> ArrayType {
        let ref = LLVMArrayType(elementType.ref, count)
        return wrapType(ref!) as! ArrayType
    }

    func mdNode(_ elements: [Metadata]) -> Metadata {
        var elems: [LLVMMetadataRef?] = elements.map { $0.ref }
        let ref = elems.withUnsafeMutableBufferPointer { buffer in
            LLVMMDNodeInContext2(self.ref, buffer.baseAddress, buffer.count)
        }
        return Metadata(ref: ref!)
    }

    func metadataAsValue(_ metadata: Metadata) -> Value {
        Value(ref: LLVMMetadataAsValue(self.ref, metadata.ref), context: self)
    }

    func vectorType(elementType: Type, count: UInt32) -> VectorType {
        let ref = LLVMVectorType(elementType.ref, count)
        return wrapType(ref!) as! VectorType
    }

    func wrapType(_ ref: LLVMTypeRef) -> Type {
        if let cached = typeCache[ref] {
            return cached
        }
        let kind = LLVMGetTypeKind(ref)
        let type: Type
        switch kind {
        case LLVMVoidTypeKind:
            type = VoidType(ref: ref, context: self)
        case LLVMHalfTypeKind, LLVMFloatTypeKind, LLVMDoubleTypeKind,
             LLVMX86_FP80TypeKind, LLVMFP128TypeKind, LLVMPPC_FP128TypeKind,
             LLVMBFloatTypeKind:
            type = FloatType(ref: ref, context: self)
        case LLVMIntegerTypeKind:
            type = IntegerType(ref: ref, context: self)
        case LLVMFunctionTypeKind:
            type = FunctionType(ref: ref, context: self)
        case LLVMStructTypeKind:
            type = StructType(ref: ref, context: self)
        case LLVMArrayTypeKind:
            type = ArrayType(ref: ref, context: self)
        case LLVMPointerTypeKind:
            type = PointerType(ref: ref, context: self)
        case LLVMVectorTypeKind, LLVMScalableVectorTypeKind:
            type = VectorType(ref: ref, context: self)
        case LLVMLabelTypeKind:
            type = LabelType(ref: ref, context: self)
        case LLVMTokenTypeKind:
            type = TokenType(ref: ref, context: self)
        case LLVMMetadataTypeKind:
            type = MetadataType(ref: ref, context: self)
        case LLVMTargetExtTypeKind:
            type = TargetExtType(ref: ref, context: self)
        default:
            type = Type(ref: ref, context: self)
        }
        typeCache[ref] = type
        return type
    }

    func wrapConstant(_ ref: LLVMValueRef) -> Constant {
        if let cached = constantCache[ref] {
            return cached
        }
        let constant: Constant
        if LLVMIsAConstantInt(ref) != nil {
            constant = ConstantInt(ref: ref, context: self)
        } else if LLVMIsAConstantFP(ref) != nil {
            constant = ConstantFP(ref: ref, context: self)
        } else {
            constant = Constant(ref: ref, context: self)
        }
        constantCache[ref] = constant
        return constant
    }
}
