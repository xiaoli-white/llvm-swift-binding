#ifndef LLVM_SHIM_H
#define LLVM_SHIM_H

void shim_initialize_all_targets(void);
void shim_initialize_all_target_infos(void);
void shim_initialize_all_target_mcs(void);
void shim_initialize_all_asm_printers(void);
void shim_initialize_native_target(void);
void shim_initialize_all_disassemblers(void);

#endif
