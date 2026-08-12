import cLLVM

private let _initializeTargets: Void = {
    LLVMInitializeNativeTarget()
    LLVMInitializeAllTargets()
    LLVMInitializeAllTargetInfos()
    LLVMInitializeAllTargetMCs()
    LLVMInitializeAllAsmPrinters()
    LLVMInitializeAllDisassemblers()
}()

public final class Target {
    public let ref: LLVMTargetRef

    public init(ref: LLVMTargetRef) {
        self.ref = ref
    }

    public static func fromTriple(_ triple: String) throws -> Target {
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

    public var name: String {
        String(cString: LLVMGetTargetName(ref)!)
    }

    public var description: String {
        String(cString: LLVMGetTargetDescription(ref)!)
    }

    public var hasTargetMachine: Bool {
        LLVMTargetHasTargetMachine(ref) != 0
    }
}

public final class TargetMachine {
    public let ref: LLVMTargetMachineRef
    public var ownsRef: Bool = true

    public init(target: Target,
                triple: String,
                cpu: String? = nil,
                features: String? = nil,
                optLevel: LLVMCodeGenOptLevel = LLVMCodeGenLevelDefault,
                relocMode: LLVMRelocMode = LLVMRelocDefault,
                codeModel: LLVMCodeModel = LLVMCodeModelDefault)
    {
        let cpuStr = cpu ?? ""
        let featuresStr = features ?? ""
        ref = cpuStr.withCString { cpuPtr in
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

    public init(ref: LLVMTargetMachineRef) {
        self.ref = ref
        ownsRef = false
    }

    deinit {
        if ownsRef {
            LLVMDisposeTargetMachine(ref)
        }
    }

    public static var defaultTriple: String {
        let ptr = LLVMGetDefaultTargetTriple()!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public static var hostCPUName: String {
        let ptr = LLVMGetHostCPUName()!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public static func initializeAllTargets() {
        _ = _initializeTargets
    }

    public var target: Target {
        Target(ref: LLVMGetTargetMachineTarget(ref))
    }

    public var triple: String {
        let ptr = LLVMGetTargetMachineTriple(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public var cpu: String {
        let ptr = LLVMGetTargetMachineCPU(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public var featureString: String {
        let ptr = LLVMGetTargetMachineFeatureString(ref)!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public func emitToFile(module: Module,
                           _ filename: String,
                           fileType: LLVMCodeGenFileType = LLVMObjectFile) throws
    {
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = filename.withCString { filenamePtr -> Int32 in
            LLVMTargetMachineEmitToFile(ref, module.ref, filenamePtr, fileType, &errMsg)
        }
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.emitFailed(message: msg)
        }
    }
}
