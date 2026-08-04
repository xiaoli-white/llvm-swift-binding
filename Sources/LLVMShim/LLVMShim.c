#include "LLVMShim.h"
#include <llvm-c/Target.h>

void shim_initialize_all_targets(void) {
    LLVMInitializeAllTargets();
}

void shim_initialize_all_target_infos(void) {
    LLVMInitializeAllTargetInfos();
}

void shim_initialize_all_target_mcs(void) {
    LLVMInitializeAllTargetMCs();
}

void shim_initialize_all_asm_printers(void) {
    LLVMInitializeAllAsmPrinters();
}

void shim_initialize_native_target(void) {
    LLVMInitializeNativeTarget();
}

void shim_initialize_all_disassemblers(void) {
    LLVMInitializeAllDisassemblers();
}
