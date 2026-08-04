import cLLVM

final class Module {
    let ref: LLVMModuleRef
    let context: Context
    var ownsRef: Bool = true

    init(name: String, in context: Context) {
        self.ref = LLVMModuleCreateWithNameInContext(name, context.ref)!
        self.context = context
    }

    init(ref: LLVMModuleRef, context: Context) {
        self.ref = ref
        self.context = context
    }

    deinit {
        if ownsRef {
            LLVMDisposeModule(ref)
        }
    }

    func dump() {
        LLVMDumpModule(ref)
    }

    var irString: String {
        let ptr = LLVMPrintModuleToString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    func addFunction(_ name: String, type: FunctionType) -> Function {
        let funcRef = LLVMAddFunction(ref, name, type.ref)!
        return Function(ref: funcRef, module: self)
    }

    func function(named name: String) -> Function? {
        var found: LLVMValueRef? = nil
        name.withCString { namePtr in
            found = LLVMGetNamedFunctionWithLength(ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return Function(ref: ref, module: self)
    }

    var functions: [Function] {
        var result: [Function] = []
        guard let first = LLVMGetFirstFunction(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let fn = current {
            result.append(Function(ref: fn, module: self))
            current = LLVMGetNextFunction(fn)
        }
        return result
    }

    func addAlias(_ name: String, type: Type, aliasee: Value, addressSpace: UInt32 = 0) -> GlobalAlias {
        let ref = LLVMAddAlias2(self.ref, type.ref, addressSpace, aliasee.ref, name)!
        return GlobalAlias(ref: ref, module: self)
    }

    func alias(named name: String) -> GlobalAlias? {
        var found: LLVMValueRef? = nil
        name.withCString { namePtr in
            found = LLVMGetNamedGlobalAlias(ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return GlobalAlias(ref: ref, module: self)
    }

    var aliases: [GlobalAlias] {
        var result: [GlobalAlias] = []
        guard let first = LLVMGetFirstGlobalAlias(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let alias = current {
            result.append(GlobalAlias(ref: alias, module: self))
            current = LLVMGetNextGlobalAlias(alias)
        }
        return result
    }

    func addIFunc(_ name: String, type: FunctionType, resolver: Value, addressSpace: UInt32 = 0) -> GlobalIFunc {
        let ref = LLVMAddGlobalIFunc(ref, name, name.utf8.count, type.ref, addressSpace, resolver.ref)!
        return GlobalIFunc(ref: ref, module: self)
    }

    func ifunc(named name: String) -> GlobalIFunc? {
        var found: LLVMValueRef? = nil
        name.withCString { namePtr in
            found = LLVMGetNamedGlobalIFunc(ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return GlobalIFunc(ref: ref, module: self)
    }

    var ifuncs: [GlobalIFunc] {
        var result: [GlobalIFunc] = []
        guard let first = LLVMGetFirstGlobalIFunc(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let ifunc = current {
            result.append(GlobalIFunc(ref: ifunc, module: self))
            current = LLVMGetNextGlobalIFunc(ifunc)
        }
        return result
    }

    func addGlobal(_ name: String, type: Type) -> GlobalVariable {
        let ref = LLVMAddGlobal(self.ref, type.ref, name)!
        return GlobalVariable(ref: ref, module: self)
    }

    func global(named name: String) -> GlobalVariable? {
        var found: LLVMValueRef? = nil
        name.withCString { namePtr in
            found = LLVMGetNamedGlobalWithLength(self.ref, namePtr, name.utf8.count)
        }
        guard let ref = found else { return nil }
        return GlobalVariable(ref: ref, module: self)
    }

    var globals: [GlobalVariable] {
        var result: [GlobalVariable] = []
        guard let first = LLVMGetFirstGlobal(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let gv = current {
            result.append(GlobalVariable(ref: gv, module: self))
            current = LLVMGetNextGlobal(gv)
        }
        return result
    }

    var target: String {
        get { String(cString: LLVMGetTarget(ref)!) }
        set { LLVMSetTarget(ref, newValue) }
    }

    func addNamedMetadataOperand(_ name: String, _ node: Value) {
        name.withCString { namePtr in
            LLVMAddNamedMetadataOperand(ref, namePtr, node.ref)
        }
    }

    func namedMetadataOperandCount(_ name: String) -> UInt32 {
        name.withCString { namePtr in
            LLVMGetNamedMetadataNumOperands(ref, namePtr)
        }
    }

    func namedMetadataOperands(_ name: String) -> [Value] {
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
