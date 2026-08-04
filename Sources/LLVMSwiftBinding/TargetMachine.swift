import cLLVM
import LLVMShim

private let _initializeTargets: Void = {
    shim_initialize_native_target()
    shim_initialize_all_targets()
    shim_initialize_all_target_infos()
    shim_initialize_all_target_mcs()
    shim_initialize_all_asm_printers()
    shim_initialize_all_disassemblers()
}()

final class Target {
    let ref: LLVMTargetRef

    init(ref: LLVMTargetRef) {
        self.ref = ref
    }

    static func fromTriple(_ triple: String) throws -> Target {
        var target: LLVMTargetRef? = nil
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = triple.withCString { triplePtr -> Int32 in
            LLVMGetTargetFromTriple(triplePtr, &target, &errMsg)
        }
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.targetNotFound(triple: "\(triple): \(msg)")
        }
        return Target(ref: target!)
    }

    var name: String {
        String(cString: LLVMGetTargetName(ref)!)
    }

    var hasTargetMachine: Bool {
        LLVMTargetHasTargetMachine(ref) != 0
    }
}

final class TargetMachine {
    let ref: LLVMTargetMachineRef
    var ownsRef: Bool = true

    init(target: Target,
         triple: String,
         cpu: String? = nil,
         features: String? = nil,
         optLevel: LLVMCodeGenOptLevel = LLVMCodeGenLevelDefault,
         relocMode: LLVMRelocMode = LLVMRelocDefault,
         codeModel: LLVMCodeModel = LLVMCodeModelDefault) {
        let cpuStr = cpu ?? ""
        let featuresStr = features ?? ""
        self.ref = cpuStr.withCString { cpuPtr in
            featuresStr.withCString { featuresPtr in
                triple.withCString { triplePtr in
                    LLVMCreateTargetMachine(
                        target.ref, triplePtr, cpuPtr, featuresPtr,
                        optLevel, relocMode, codeModel
                    )!
                }
            }
        }
    }

    init(ref: LLVMTargetMachineRef) {
        self.ref = ref
        self.ownsRef = false
    }

    deinit {
        if ownsRef {
            LLVMDisposeTargetMachine(ref)
        }
    }

    static var defaultTriple: String {
        let ptr = LLVMGetDefaultTargetTriple()!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    static var hostCPUName: String {
        let ptr = LLVMGetHostCPUName()!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    static func initializeAllTargets() {
        _ = _initializeTargets
    }

    var target: Target {
        Target(ref: LLVMGetTargetMachineTarget(ref))
    }

    var triple: String {
        let ptr = LLVMGetTargetMachineTriple(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    var cpu: String {
        let ptr = LLVMGetTargetMachineCPU(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    var featureString: String {
        let ptr = LLVMGetTargetMachineFeatureString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    func emitToFile(module: Module,
                    _ filename: String,
                    fileType: LLVMCodeGenFileType = LLVMObjectFile) throws {
        var errMsg: UnsafeMutablePointer<CChar>? = nil
        let result = filename.withCString { filenamePtr -> Int32 in
            LLVMTargetMachineEmitToFile(ref, module.ref, filenamePtr, fileType, &errMsg)
        }
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.emitFailed(message: msg)
        }
    }
}
