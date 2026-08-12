import cLLVM

public final class Module {
    public let ref: LLVMModuleRef
    public let context: Context
    public var ownsRef: Bool = true

    public init(name: String, in context: Context) {
        ref = LLVMModuleCreateWithNameInContext(name, context.ref)!
        self.context = context
    }

    public init(ref: LLVMModuleRef, context: Context) {
        self.ref = ref
        self.context = context
    }

    deinit {
        if ownsRef {
            LLVMDisposeModule(ref)
        }
    }

    public func dump() {
        LLVMDumpModule(ref)
    }

    public func clone() -> Module {
        Module(ref: LLVMCloneModule(ref), context: context)
    }

    public var irString: String {
        let ptr = LLVMPrintModuleToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public func addFunction(_ name: String, type: FunctionType) -> Function {
        let funcRef = LLVMAddFunction(ref, name, type.ref)!
        return Function(ref: funcRef, module: self)
    }

    public func function(named name: String) -> Function? {
        var found: LLVMValueRef?
        name.withCString { namePtr in
            found = LLVMGetNamedFunctionWithLength(ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return Function(ref: ref, module: self)
    }

    public func getOrInsertFunction(_ name: String, type: FunctionType) -> Function {
        let nameLength = name.utf8.count
        let fnRef = name.withCString { namePtr in
            LLVMGetOrInsertFunction(ref, namePtr, nameLength, type.ref)
        }
        return Function(ref: fnRef!, module: self)
    }

    public var functions: [Function] {
        var result: [Function] = []
        guard let first = LLVMGetFirstFunction(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let fn = current {
            result.append(Function(ref: fn, module: self))
            current = LLVMGetNextFunction(fn)
        }
        return result
    }

    public func addAlias(_ name: String, type: Type, aliasee: Value, addressSpace: UInt32 = 0) -> GlobalAlias {
        let ref = LLVMAddAlias2(ref, type.ref, addressSpace, aliasee.ref, name)!
        return GlobalAlias(ref: ref, module: self)
    }

    public func alias(named name: String) -> GlobalAlias? {
        var found: LLVMValueRef?
        name.withCString { namePtr in
            found = LLVMGetNamedGlobalAlias(ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return GlobalAlias(ref: ref, module: self)
    }

    public var aliases: [GlobalAlias] {
        var result: [GlobalAlias] = []
        guard let first = LLVMGetFirstGlobalAlias(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let alias = current {
            result.append(GlobalAlias(ref: alias, module: self))
            current = LLVMGetNextGlobalAlias(alias)
        }
        return result
    }

    public func addIFunc(_ name: String, type: FunctionType, resolver: Value, addressSpace: UInt32 = 0) -> GlobalIFunc {
        let ref = LLVMAddGlobalIFunc(ref, name, name.utf8.count, type.ref, addressSpace, resolver.ref)!
        return GlobalIFunc(ref: ref, module: self)
    }

    public func ifunc(named name: String) -> GlobalIFunc? {
        var found: LLVMValueRef?
        name.withCString { namePtr in
            found = LLVMGetNamedGlobalIFunc(ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return GlobalIFunc(ref: ref, module: self)
    }

    public var ifuncs: [GlobalIFunc] {
        var result: [GlobalIFunc] = []
        guard let first = LLVMGetFirstGlobalIFunc(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let ifunc = current {
            result.append(GlobalIFunc(ref: ifunc, module: self))
            current = LLVMGetNextGlobalIFunc(ifunc)
        }
        return result
    }

    public func addGlobal(_ name: String, type: Type) -> GlobalVariable {
        let ref = LLVMAddGlobal(ref, type.ref, name)!
        return GlobalVariable(ref: ref, module: self)
    }

    public func global(named name: String) -> GlobalVariable? {
        var found: LLVMValueRef?
        name.withCString { namePtr in
            found = LLVMGetNamedGlobalWithLength(self.ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return GlobalVariable(ref: ref, module: self)
    }

    public var globals: [GlobalVariable] {
        var result: [GlobalVariable] = []
        guard let first = LLVMGetFirstGlobal(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let gv = current {
            result.append(GlobalVariable(ref: gv, module: self))
            current = LLVMGetNextGlobal(gv)
        }
        return result
    }

    public var target: String {
        get { String(cString: LLVMGetTarget(ref)!) }
        set { LLVMSetTarget(ref, newValue) }
    }

    public var identifier: String {
        get {
            var length = 0
            guard let ptr = LLVMGetModuleIdentifier(ref, &length) else { return "" }
            let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self)
        }
        set {
            newValue.withCString { ptr in
                LLVMSetModuleIdentifier(ref, ptr, newValue.utf8.count)
            }
        }
    }

    public var sourceFileName: String {
        get {
            var length = 0
            guard let ptr = LLVMGetSourceFileName(ref, &length) else { return "" }
            let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self)
        }
        set {
            newValue.withCString { ptr in
                LLVMSetSourceFileName(ref, ptr, newValue.utf8.count)
            }
        }
    }

    public var inlineAsm: String {
        get {
            var length = 0
            guard let ptr = LLVMGetModuleInlineAsm(ref, &length) else { return "" }
            let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
            return String(decoding: bytes, as: UTF8.self)
        }
        set {
            newValue.withCString { ptr in
                LLVMSetModuleInlineAsm2(ref, ptr, newValue.utf8.count)
            }
        }
    }

    public func addNamedMetadataOperand(_ name: String, _ node: Value) {
        name.withCString { namePtr in
            LLVMAddNamedMetadataOperand(ref, namePtr, node.ref)
        }
    }

    public var namedMetadataNames: [String] {
        var result: [String] = []
        guard let first = LLVMGetFirstNamedMetadata(ref) else { return [] }
        var current: LLVMNamedMDNodeRef? = first
        while let node = current {
            var length = 0
            if let ptr = LLVMGetNamedMetadataName(node, &length) {
                let bytes = UnsafeBufferPointer(start: ptr, count: length).map { UInt8(bitPattern: $0) }
                result.append(String(decoding: bytes, as: UTF8.self))
            }
            current = LLVMGetNextNamedMetadata(node)
        }
        return result
    }

    public func namedMetadataOperandCount(_ name: String) -> UInt32 {
        name.withCString { namePtr in
            LLVMGetNamedMetadataNumOperands(ref, namePtr)
        }
    }

    public func namedMetadataOperands(_ name: String) -> [Value] {
        let count = Int(namedMetadataOperandCount(name))
        guard count > 0 else { return [] }
        var nodes = [LLVMValueRef?](repeating: nil, count: count)
        nodes.withUnsafeMutableBufferPointer { buffer in
            name.withCString { namePtr in
                LLVMGetNamedMetadataOperands(ref, namePtr, buffer.baseAddress)
            }
        }
        return nodes.map { Value(ref: $0!, context: context, module: self) }
    }
}
