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

    public static var all: [Target] {
        var result: [Target] = []
        guard let first = LLVMGetFirstTarget() else { return [] }
        var current: LLVMTargetRef? = first
        while let target = current {
            result.append(Target(ref: target))
            current = LLVMGetNextTarget(target)
        }
        return result
    }

    public static func named(_ name: String) -> Target? {
        guard let ref = name.withCString({ LLVMGetTargetFromName($0) }) else { return nil }
        return Target(ref: ref)
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

    public static var hostCPUFeatures: String {
        let ptr = LLVMGetHostCPUFeatures()!
        defer { LLVMDisposeMessage(ptr) }
        return String(cString: ptr)
    }

    public static func normalizedTriple(_ triple: String) -> String {
        let ptr = triple.withCString { LLVMNormalizeTargetTriple($0) }!
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

    public func setAsmVerbosity(_ verbose: Bool) {
        LLVMSetTargetMachineAsmVerbosity(ref, verbose ? 1 : 0)
    }

    public func setFastISel(_ enabled: Bool) {
        LLVMSetTargetMachineFastISel(ref, enabled ? 1 : 0)
    }

    public func setGlobalISel(_ enabled: Bool) {
        LLVMSetTargetMachineGlobalISel(ref, enabled ? 1 : 0)
    }

    public func setGlobalISelAbort(_ mode: LLVMGlobalISelAbortMode) {
        LLVMSetTargetMachineGlobalISelAbort(ref, mode)
    }

    public func setMachineOutliner(_ enabled: Bool) {
        LLVMSetTargetMachineMachineOutliner(ref, enabled ? 1 : 0)
    }

    public func emitToMemoryBuffer(module: Module,
                                   fileType: LLVMCodeGenFileType = LLVMObjectFile) throws -> MemoryBuffer
    {
        var outBuffer: LLVMMemoryBufferRef?
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = LLVMTargetMachineEmitToMemoryBuffer(ref, module.ref, fileType, &errMsg, &outBuffer)
        if result != 0 {
            let msg = errorMessage(from: errMsg)
            throw LLVMError.emitFailed(message: msg)
        }
        return MemoryBuffer(ref: outBuffer!)
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

    public init(target: Target, triple: String, options: TargetMachineOptions) {
        ref = triple.withCString { triplePtr in
            LLVMCreateTargetMachineWithOptions(target.ref, triplePtr, options.ref)!
        }
    }
}

public final class TargetMachineOptions {
    public let ref: LLVMTargetMachineOptionsRef

    public init() {
        ref = LLVMCreateTargetMachineOptions()
    }

    deinit {
        LLVMDisposeTargetMachineOptions(ref)
    }

    public func setCPU(_ cpu: String) {
        cpu.withCString { LLVMTargetMachineOptionsSetCPU(ref, $0) }
    }

    public func setFeatures(_ features: String) {
        features.withCString { LLVMTargetMachineOptionsSetFeatures(ref, $0) }
    }

    public func setABI(_ abi: String) {
        abi.withCString { LLVMTargetMachineOptionsSetABI(ref, $0) }
    }

    public func setCodeGenOptLevel(_ level: LLVMCodeGenOptLevel) {
        LLVMTargetMachineOptionsSetCodeGenOptLevel(ref, level)
    }

    public func setRelocMode(_ mode: LLVMRelocMode) {
        LLVMTargetMachineOptionsSetRelocMode(ref, mode)
    }

    public func setCodeModel(_ model: LLVMCodeModel) {
        LLVMTargetMachineOptionsSetCodeModel(ref, model)
    }
}
