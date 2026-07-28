import cLLVM

class Instruction: Value {}

final class ReturnInst: Instruction {}

final class BinaryOperator: Instruction {}

final class AllocaInst: Instruction {}

final class LoadInst: Instruction {}

final class StoreInst: Instruction {}

final class BranchInst: Instruction {}

final class SwitchInst: Instruction {
    func addCase(_ on: Value, _ dest: BasicBlock) {
        LLVMAddCase(ref, on.ref, dest.ref)
    }
}

final class ICmpInst: Instruction {}

final class FCmpInst: Instruction {}

final class CallInst: Instruction {}

final class PHINode: Instruction {
    func addIncoming(_ value: Value, from block: BasicBlock) {
        var val: LLVMValueRef? = value.ref
        var blk: LLVMBasicBlockRef? = block.ref
        LLVMAddIncoming(ref, &val, &blk, 1)
    }

    func addIncoming(_ values: [(value: Value, block: BasicBlock)]) {
        let count = UInt32(values.count)
        var vals: [LLVMValueRef?] = values.map { $0.value.ref }
        var blks: [LLVMBasicBlockRef?] = values.map { $0.block.ref }
        vals.withUnsafeMutableBufferPointer { valBuf in
            blks.withUnsafeMutableBufferPointer { blkBuf in
                LLVMAddIncoming(ref, valBuf.baseAddress, blkBuf.baseAddress, count)
            }
        }
    }
}

final class SelectInst: Instruction {}

final class GetElementPtrInst: Instruction {}

final class CastInst: Instruction {}
