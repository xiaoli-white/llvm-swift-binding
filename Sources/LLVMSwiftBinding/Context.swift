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

    func poison(_ type: Type) -> PoisonValue {
        let ref = LLVMGetPoison(type.ref)!
        return PoisonValue(ref: ref, context: self)
    }

    func constantFP(ofString str: String, type: FloatType) -> ConstantFP {
        let ref = str.withCString { strPtr in
            LLVMConstRealOfStringAndSize(type.ref, strPtr, UInt32(str.utf8.count))
        }
        return wrapConstant(ref!) as! ConstantFP
    }

    func constantString(_ str: String, dontNullTerminate: Bool = false) -> Constant {
        let ref = str.withCString { strPtr in
            LLVMConstStringInContext2(self.ref, strPtr, str.utf8.count, dontNullTerminate ? 1 : 0)
        }
        return wrapConstant(ref!)
    }

    func constantReal(ofString str: String, type: FloatType) -> ConstantFP {
        let ref = str.withCString { strPtr in
            LLVMConstRealOfStringAndSize(type.ref, strPtr, UInt32(str.utf8.count))
        }
        return wrapConstant(ref!) as! ConstantFP
    }

    func constantNeg(_ value: Constant) -> Constant {
        wrapConstant(LLVMConstNeg(value.ref)!)
    }

    func constantAdd(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstAdd(lhs.ref, rhs.ref)!)
    }

    func constantSub(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstSub(lhs.ref, rhs.ref)!)
    }

    func constantTrunc(_ value: Constant, to type: Type) -> Constant {
        wrapConstant(LLVMConstTrunc(value.ref, type.ref)!)
    }

    func constantPtrToInt(_ value: Constant, to type: Type) -> Constant {
        wrapConstant(LLVMConstPtrToInt(value.ref, type.ref)!)
    }

    func constantIntToPtr(_ value: Constant, to type: Type) -> Constant {
        wrapConstant(LLVMConstIntToPtr(value.ref, type.ref)!)
    }

    func constantBitCast(_ value: Constant, to type: Type) -> Constant {
        wrapConstant(LLVMConstBitCast(value.ref, type.ref)!)
    }

    func constantArray(_ values: [Constant], elementType: Type) -> ConstantArray {
        var valRefs: [LLVMValueRef?] = values.map { $0.ref }
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstArray2(elementType.ref, buffer.baseAddress, UInt64(values.count))
        }
        return ConstantArray(ref: ref!, context: self)
    }

    func constantDataArray(bytes: [UInt8], type: Type) -> ConstantDataArray {
        let chars = bytes.map { CChar(bitPattern: $0) }
        let ref = chars.withUnsafeBufferPointer { buffer in
            LLVMConstDataArray(type.ref, buffer.baseAddress, buffer.count)
        }
        return ConstantDataArray(ref: ref!, context: self)
    }

    func constantVector(_ values: [Constant]) -> ConstantVector {
        var valRefs: [LLVMValueRef?] = values.map { $0.ref }
        let ref = valRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstVector(buffer.baseAddress, UInt32(values.count))
        }
        return ConstantVector(ref: ref!, context: self)
    }

    func constantInt(ofString str: String, type: IntegerType, radix: UInt8 = 0) -> ConstantInt {
        let (clean, effectiveRadix) = Self.resolveRadix(str, radix: radix)
        let ref = clean.withCString { strPtr in
            LLVMConstIntOfStringAndSize(type.ref, strPtr, UInt32(clean.utf8.count), effectiveRadix)
        }
        return wrapConstant(ref!) as! ConstantInt
    }

    private static func resolveRadix(_ str: String, radix: UInt8) -> (String, UInt8) {
        let lower = str.lowercased()
        if radix != 0 {
            switch radix {
            case 16:
                if lower.hasPrefix("0x") { return (String(str.dropFirst(2)), 16) }
            case 2:
                if lower.hasPrefix("0b") { return (String(str.dropFirst(2)), 2) }
            case 8:
                if lower.hasPrefix("0o") { return (String(str.dropFirst(2)), 8) }
            default:
                break
            }
            return (str, radix)
        }
        if lower.hasPrefix("0x") { return (String(str.dropFirst(2)), 16) }
        if lower.hasPrefix("0b") { return (String(str.dropFirst(2)), 2) }
        if lower.hasPrefix("0o") { return (String(str.dropFirst(2)), 8) }
        return (str, 10)
    }

    func constantAllOnes(_ type: Type) -> Constant {
        wrapConstant(LLVMConstAllOnes(type.ref)!)
    }

    func constantPointerNull(_ type: Type) -> Constant {
        wrapConstant(LLVMConstPointerNull(type.ref)!)
    }

    func constantNot(_ value: Constant) -> Constant {
        wrapConstant(LLVMConstNot(value.ref)!)
    }

    func constantXor(_ lhs: Constant, _ rhs: Constant) -> Constant {
        wrapConstant(LLVMConstXor(lhs.ref, rhs.ref)!)
    }

    func constantGEP(_ elementType: Type, _ value: Constant, indices: [Constant]) -> Constant {
        var idxRefs: [LLVMValueRef?] = indices.map { $0.ref }
        let ref = idxRefs.withUnsafeMutableBufferPointer { buffer in
            LLVMConstGEP2(elementType.ref, value.ref, buffer.baseAddress, UInt32(indices.count))
        }
        return wrapConstant(ref!)
    }

    func constantTruncOrBitCast(_ value: Constant, to type: Type) -> Constant {
        wrapConstant(LLVMConstTruncOrBitCast(value.ref, type.ref)!)
    }

    func constantPointerCast(_ value: Constant, to type: Type) -> Constant {
        wrapConstant(LLVMConstPointerCast(value.ref, type.ref)!)
    }

    func constantAddrSpaceCast(_ value: Constant, to type: Type) -> Constant {
        wrapConstant(LLVMConstAddrSpaceCast(value.ref, type.ref)!)
    }

    func constantExtractElement(_ vector: Constant, _ index: Constant) -> Constant {
        wrapConstant(LLVMConstExtractElement(vector.ref, index.ref)!)
    }

    func constantInsertElement(_ vector: Constant, _ element: Constant, _ index: Constant) -> Constant {
        wrapConstant(LLVMConstInsertElement(vector.ref, element.ref, index.ref)!)
    }

    func constantShuffleVector(_ v1: Constant, _ v2: Constant, mask: Constant) -> Constant {
        wrapConstant(LLVMConstShuffleVector(v1.ref, v2.ref, mask.ref)!)
    }

    func constantInlineAsm(_ type: Type, asmString: String, constraints: String, hasSideEffects: Bool, isAlignStack: Bool, dialect: LLVMInlineAsmDialect = LLVMInlineAsmDialectATT, canThrow: Bool = false) -> Value {
        let ref = asmString.withCString { asmPtr in
            constraints.withCString { cPtr in
                LLVMGetInlineAsm(type.ref, asmPtr, asmString.utf8.count, cPtr, constraints.utf8.count, hasSideEffects ? 1 : 0, isAlignStack ? 1 : 0, dialect, canThrow ? 1 : 0)
            }
        }
        return Value(ref: ref!, context: self)
    }

    func blockAddress(function: Function, block: BasicBlock) -> BlockAddress {
        let ref = LLVMBlockAddress(function.ref, block.ref)
        return BlockAddress(ref: ref!, context: self)
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

    func namedStructType(name: String, elementTypes: [Type]? = nil, isPacked: Bool = false) -> StructType {
        let ref = LLVMStructCreateNamed(self.ref, name)
        let type = wrapType(ref!) as! StructType
        if let elementTypes {
            var members: [LLVMTypeRef?] = elementTypes.map { $0.ref }
            members.withUnsafeMutableBufferPointer { buffer in
                LLVMStructSetBody(ref, buffer.baseAddress, UInt32(elementTypes.count), isPacked ? 1 : 0)
            }
        }
        return type
    }

    func arrayType(elementType: Type, count: UInt32) -> ArrayType {
        let ref = LLVMArrayType(elementType.ref, count)
        return wrapType(ref!) as! ArrayType
    }

    func vectorType(elementType: Type, count: UInt32) -> VectorType {
        let ref = LLVMVectorType(elementType.ref, count)
        return wrapType(ref!) as! VectorType
    }

    func scalableVectorType(elementType: Type, count: UInt32) -> VectorType {
        let ref = LLVMScalableVectorType(elementType.ref, count)
        return wrapType(ref!) as! VectorType
    }

    func targetExtType(name: String, typeParams: [Type] = [], intParams: [UInt32] = []) -> TargetExtType {
        var typeRefs: [LLVMTypeRef?] = typeParams.map { $0.ref }
        let ref = typeRefs.withUnsafeMutableBufferPointer { typeBuf in
            intParams.withUnsafeBufferPointer { intBuf in
                LLVMTargetExtTypeInContext(self.ref, name, typeBuf.baseAddress, UInt32(typeParams.count), UnsafeMutablePointer(mutating: intBuf.baseAddress), UInt32(intParams.count))
            }
        }
        return wrapType(ref!) as! TargetExtType
    }

    func mdNode(_ elements: [Metadata]) -> Metadata {
        var elems: [LLVMMetadataRef?] = elements.map { $0.ref }
        let ref = elems.withUnsafeMutableBufferPointer { buffer in
            LLVMMDNodeInContext2(self.ref, buffer.baseAddress, buffer.count)
        }
        return Metadata(ref: ref!)
    }

    func mdString(_ str: String) -> Metadata {
        let ref = str.withCString { strPtr in
            LLVMMDStringInContext2(self.ref, strPtr, str.utf8.count)
        }
        return Metadata(ref: ref!)
    }

    func metadataAsValue(_ metadata: Metadata) -> Value {
        Value(ref: LLVMMetadataAsValue(self.ref, metadata.ref), context: self)
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
        } else if LLVMIsAUndefValue(ref) != nil {
            constant = UndefValue(ref: ref, context: self)
        } else if LLVMIsAPoisonValue(ref) != nil {
            constant = PoisonValue(ref: ref, context: self)
        } else if LLVMIsAConstantTokenNone(ref) != nil {
            constant = ConstantTokenNone(ref: ref, context: self)
        } else if LLVMIsAConstantAggregateZero(ref) != nil {
            constant = ConstantAggregateZero(ref: ref, context: self)
        } else if LLVMIsAConstantDataArray(ref) != nil {
            constant = ConstantDataArray(ref: ref, context: self)
        } else if LLVMIsAConstantExpr(ref) != nil {
            constant = ConstantExpr(ref: ref, context: self)
        } else if LLVMIsAConstantVector(ref) != nil {
            constant = ConstantVector(ref: ref, context: self)
        } else if LLVMIsABlockAddress(ref) != nil {
            constant = BlockAddress(ref: ref, context: self)
        } else {
            constant = Constant(ref: ref, context: self)
        }
        constantCache[ref] = constant
        return constant
    }
}
