import cLLVM

public final class BasicBlock {
    public let ref: LLVMBasicBlockRef
    public let function: Function
    public let module: Module

    public init(ref: LLVMBasicBlockRef, function: Function, module: Module) {
        self.ref = ref
        self.function = function
        self.module = module
    }

    public var context: Context { module.context }

    public var asValue: Value {
        Value(ref: LLVMBasicBlockAsValue(ref)!, context: context, module: module)
    }

    public var name: String {
        get { String(cString: LLVMGetBasicBlockName(ref)) }
        set { LLVMSetValueName2(ref, newValue, newValue.utf8.count) }
    }

    public var terminator: Instruction? {
        guard let inst = LLVMGetBasicBlockTerminator(ref) else { return nil }
        return Instruction.wrap(inst, context: context, module: module)
    }

    public func insertBasicBlock(_ name: String) -> BasicBlock {
        let block = LLVMInsertBasicBlockInContext(context.ref, ref, name)!
        return BasicBlock(ref: block, function: function, module: module)
    }

    public func moveBasicBlock(before other: BasicBlock) {
        LLVMMoveBasicBlockBefore(ref, other.ref)
    }

    public func eraseFromParent() {
        LLVMDeleteBasicBlock(ref)
    }

    public var firstInstruction: Instruction? {
        guard let inst = LLVMGetFirstInstruction(ref) else { return nil }
        return Instruction.wrap(inst, context: context, module: module)
    }

    public var lastInstruction: Instruction? {
        guard let inst = LLVMGetLastInstruction(ref) else { return nil }
        return Instruction.wrap(inst, context: context, module: module)
    }

    public var instructions: [Instruction] {
        var result: [Instruction] = []
        guard let first = LLVMGetFirstInstruction(ref) else { return [] }
        var current: LLVMValueRef? = first
        while let inst = current {
            result.append(Instruction.wrap(inst, context: context, module: module))
            current = LLVMGetNextInstruction(inst)
        }
        return result
    }
}
