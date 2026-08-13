import cLLVM

public final class Attribute {
    public let ref: LLVMAttributeRef
    public let context: Context

    public init(ref: LLVMAttributeRef, context: Context) {
        self.ref = ref
        self.context = context
    }

    public var isEnum: Bool {
        LLVMIsEnumAttribute(ref) != 0
    }

    public var isString: Bool {
        LLVMIsStringAttribute(ref) != 0
    }

    public var isType: Bool {
        LLVMIsTypeAttribute(ref) != 0
    }

    public var enumKind: UInt32 {
        LLVMGetEnumAttributeKind(ref)
    }

    public var enumValue: UInt64 {
        LLVMGetEnumAttributeValue(ref)
    }

    public var stringKind: String? {
        guard isString else { return nil }
        var length: UInt32 = 0
        guard let ptr = LLVMGetStringAttributeKind(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: Int(length)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var stringValue: String? {
        guard isString else { return nil }
        var length: UInt32 = 0
        guard let ptr = LLVMGetStringAttributeValue(ref, &length) else { return nil }
        let bytes = UnsafeBufferPointer(start: ptr, count: Int(length)).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    public var typeValue: LLVMType? {
        guard isType else { return nil }
        return context.wrapType(LLVMGetTypeAttributeValue(ref)!)
    }

    public static func enumAttribute(_ kind: UInt32, value: UInt64 = 0, in context: Context) -> Attribute {
        let ref = LLVMCreateEnumAttribute(context.ref, kind, value)!
        return Attribute(ref: ref, context: context)
    }

    public static func stringAttribute(_ kind: String, value: String = "", in context: Context) -> Attribute {
        let ref = kind.withCString { kindPtr in
            value.withCString { valuePtr in
                LLVMCreateStringAttribute(
                    context.ref, kindPtr, UInt32(kind.utf8.count), valuePtr, UInt32(value.utf8.count)
                )!
            }
        }
        return Attribute(ref: ref, context: context)
    }

    public static func typeAttribute(_ kind: UInt32, type: LLVMType, in context: Context) -> Attribute {
        let ref = LLVMCreateTypeAttribute(context.ref, kind, type.ref)!
        return Attribute(ref: ref, context: context)
    }
}

public enum AttributeIndex {
    public static let returnIndex: LLVMAttributeIndex = UInt32(LLVMAttributeReturnIndex)
    public static let functionIndex: LLVMAttributeIndex = UInt32(bitPattern: Int32(LLVMAttributeFunctionIndex))

    public static func parameter(_ index: UInt32) -> LLVMAttributeIndex {
        index + 1
    }
}

public extension Value {
    func addAttribute(_ attribute: Attribute, at index: LLVMAttributeIndex) {
        LLVMAddAttributeAtIndex(ref, index, attribute.ref)
    }

    func removeEnumAttribute(kind: UInt32, at index: LLVMAttributeIndex) {
        LLVMRemoveEnumAttributeAtIndex(ref, index, kind)
    }

    func removeStringAttribute(kind: String, at index: LLVMAttributeIndex) {
        kind.withCString { kindPtr in
            LLVMRemoveStringAttributeAtIndex(ref, index, kindPtr, UInt32(kind.utf8.count))
        }
    }

    func attributes(at index: LLVMAttributeIndex) -> [Attribute] {
        let count = LLVMGetAttributeCountAtIndex(ref, index)
        guard count > 0 else { return [] }
        var attrs = [LLVMAttributeRef?](repeating: nil, count: Int(count))
        attrs.withUnsafeMutableBufferPointer { buffer in
            LLVMGetAttributesAtIndex(ref, index, buffer.baseAddress)
        }
        return attrs.map { Attribute(ref: $0!, context: context) }
    }
}

public extension CallInst {
    func addCallSiteAttribute(_ attribute: Attribute, at index: LLVMAttributeIndex) {
        LLVMAddCallSiteAttribute(ref, index, attribute.ref)
    }

    func removeCallSiteEnumAttribute(kind: UInt32, at index: LLVMAttributeIndex) {
        LLVMRemoveCallSiteEnumAttribute(ref, index, kind)
    }

    func callSiteAttributes(at index: LLVMAttributeIndex) -> [Attribute] {
        let count = LLVMGetCallSiteAttributeCount(ref, index)
        guard count > 0 else { return [] }
        var attrs = [LLVMAttributeRef?](repeating: nil, count: Int(count))
        attrs.withUnsafeMutableBufferPointer { buffer in
            LLVMGetCallSiteAttributes(ref, index, buffer.baseAddress)
        }
        return attrs.map { Attribute(ref: $0!, context: context) }
    }
}
