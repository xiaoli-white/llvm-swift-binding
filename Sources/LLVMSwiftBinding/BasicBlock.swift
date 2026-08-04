import cLLVM

final class BasicBlock {
    let ref: LLVMBasicBlockRef
    let function: Function
    let module: Module

    init(ref: LLVMBasicBlockRef, function: Function, module: Module) {
        self.ref = ref
        self.function = function
        self.module = module
    }

    var context: Context { module.context }

    var name: String {
        get { String(cString: LLVMGetBasicBlockName(ref)) }
        set { LLVMSetValueName2(ref, newValue, newValue.utf8.count) }
    }

    var terminator: Instruction? {
        guard let inst = LLVMGetBasicBlockTerminator(ref) else { return nil }
        return Instruction.wrap(inst, context: context, module: module)
    }

    func insertBasicBlock(_ name: String) -> BasicBlock {
        let block = LLVMInsertBasicBlockInContext(context.ref, ref, name)!
        return BasicBlock(ref: block, function: function, module: module)
    }

    func moveBasicBlock(before other: BasicBlock) {
        LLVMMoveBasicBlockBefore(ref, other.ref)
    }

    var firstInstruction: Instruction? {
        guard let inst = LLVMGetFirstInstruction(ref) else { return nil }
        return Instruction.wrap(inst, context: context, module: module)
    }

    var lastInstruction: Instruction? {
        guard let inst = LLVMGetLastInstruction(ref) else { return nil }
        return Instruction.wrap(inst, context: context, module: module)
    }

    var instructions: [Instruction] {
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
