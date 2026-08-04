import Testing
import Foundation
import cLLVM
@testable import LLVMSwiftBinding

@Suite(.serialized)
struct LLVMSwiftBindingTests {

@Test func helloWorldIR() {
    let ctx = Context()
    let module = Module(name: "hello", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let ir = module.irString
    #expect(ir.contains("define i32 @main()"))
    #expect(ir.contains("ret i32 42"))
}

@Test func helloWorldEndToEnd() throws {
    let ctx = Context()
    let module = Module(name: "hello", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)hello_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)hello_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func addAndCall() throws {
    let ctx = Context()
    let module = Module(name: "addcall", in: ctx)
    let i32 = ctx.int32

    let addType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let addFunc = module.addFunction("add", type: addType)
    let addEntry = addFunc.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: addEntry)
    let sum = builder.buildAdd(addFunc.parameter(at: 0), addFunc.parameter(at: 1), name: "sum")
    builder.buildRet(sum)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let mainEntry = main.appendBasicBlock("entry")
    builder.positionAtEnd(of: mainEntry)
    let result = builder.buildCall(addFunc, [ctx.constantInt(40, type: i32), ctx.constantInt(2, type: i32)], name: "result")
    builder.buildRet(result)

    let ir = module.irString
    #expect(ir.contains("define i32 @add"))
    #expect(ir.contains("define i32 @main"))
    #expect(ir.contains("call i32 @add"))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)addcall_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)addcall_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func loopWithPhi() throws {
    let ctx = Context()
    let module = Module(name: "loop", in: ctx)
    let i32 = ctx.int32

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)

    let entry = main.appendBasicBlock("entry")
    let loop = main.appendBasicBlock("loop")
    let body = main.appendBasicBlock("body")
    let done = main.appendBasicBlock("done")

    let builder = Builder(in: ctx)

    builder.positionAtEnd(of: entry)
    builder.buildBr(loop)

    builder.positionAtEnd(of: loop)
    let i = builder.buildPhi(i32, name: "i")
    i.addIncoming(ctx.constantInt(0, type: i32), from: entry)
    let cond = builder.buildICmp(LLVMIntSLT, i, ctx.constantInt(42, type: i32), name: "cond")
    builder.buildCondBr(cond, then: body, else: done)

    builder.positionAtEnd(of: body)
    let next = builder.buildAdd(i, ctx.constantInt(1, type: i32), name: "next")
    builder.buildBr(loop)
    i.addIncoming(next, from: body)

    builder.positionAtEnd(of: done)
    builder.buildRet(i)

    let ir = module.irString
    #expect(ir.contains("phi"))
    #expect(ir.contains("icmp slt"))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)loop_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)loop_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func globalVariable() throws {
    let ctx = Context()
    let module = Module(name: "global", in: ctx)
    let i32 = ctx.int32

    let answer = module.addGlobal("answer", type: i32)
    answer.initializer = ctx.constantInt(42, type: i32)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let val = builder.buildLoad(i32, answer, name: "val")
    builder.buildRet(val)

    let ir = module.irString
    #expect(ir.contains("@answer = global i32 42"))
    #expect(ir.contains("load i32"))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)global_\(UUID().uuidString).o"
    let exePath = "\(tmpDir)global_\(UUID().uuidString)"

    try tm.emitToFile(module: module, objPath)
    defer {
        try? FileManager.default.removeItem(atPath: objPath)
        try? FileManager.default.removeItem(atPath: exePath)
    }

    let linkProcess = Process()
    linkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
    linkProcess.arguments = [objPath, "-o", exePath]
    try linkProcess.run()
    linkProcess.waitUntilExit()
    #expect(linkProcess.terminationStatus == 0)

    let runProcess = Process()
    runProcess.executableURL = URL(fileURLWithPath: exePath)
    try runProcess.run()
    runProcess.waitUntilExit()
    #expect(runProcess.terminationStatus == 42)
}

@Test func irReaderRoundTrip() throws {
    let ctx = Context()
    let module = Module(name: "hello", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let ir = module.irString

    let ctx2 = Context()
    let parsed = try Module.parseIR(ir, in: ctx2)
    #expect(parsed.irString.contains("ret i32 42"))
}

@Test func bitcodeRoundTrip() throws {
    let ctx = Context()
    let module = Module(name: "bc", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let tmpDir = NSTemporaryDirectory()
    let bcPath = "\(tmpDir)bc_\(UUID().uuidString).bc"
    try module.writeBitcode(to: bcPath)
    defer { try? FileManager.default.removeItem(atPath: bcPath) }

    let ctx2 = Context()
    let parsed = try Module.parseBitcodeFile(bcPath, in: ctx2)
    #expect(parsed.irString.contains("ret i32 42"))
}

@Test(.disabled("LLVM ORC JIT crashes with glibc 2.44 tpp.c assertion on Arch Linux"))
func jitHelloWorld() throws {
    let ctx = Context()
    let module = Module(name: "jit", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let jit = try LLJIT()
    try jit.addModule(module)
    let result = try jit.runFunction("main")
    #expect(result == 42)
}

@Test(.disabled("LLVM ORC JIT crashes with glibc 2.44 tpp.c assertion on Arch Linux"))
func jitAddFunction() throws {
    let ctx = Context()
    let module = Module(name: "jitadd", in: ctx)
    let i32 = ctx.int32

    let addType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let addFunc = module.addFunction("add", type: addType)
    let addEntry = addFunc.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: addEntry)
    builder.buildRet(builder.buildAdd(addFunc.parameter(at: 0), addFunc.parameter(at: 1), name: "sum"))

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let mainEntry = main.appendBasicBlock("entry")
    builder.positionAtEnd(of: mainEntry)
    builder.buildRet(builder.buildCall(addFunc, [ctx.constantInt(40, type: i32), ctx.constantInt(2, type: i32)], name: "result"))

    let jit = try LLJIT()
    try jit.addModule(module)
    let result = try jit.runFunction("main")
    #expect(result == 42)
}

@Test func debugInfo() throws {
    let ctx = Context()
    let module = Module(name: "debug", in: ctx)
    let i32 = ctx.int32

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )

    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)
    let subType = di.createSubroutineType(file: file, returnTypes: [intType])

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let subprogram = di.createFunction(
        scope: cu,
        name: "main",
        file: file,
        line: 1,
        subroutineType: subType,
        isLocalToUnit: true,
        isDefinition: true,
        scopeLine: 1
    )
    main.setSubprogram(subprogram)

    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DICompileUnit"))
    #expect(ir.contains("!DIFile"))
    #expect(ir.contains("!DISubprogram"))
}

@Test func passManagerAnalysis() throws {
    let ctx = Context()
    let module = Module(name: "pm", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let pm = PassManager()
    pm.addAnalysisPasses(of: tm)
    pm.run(on: module)
}

@Test func moduleLinking() throws {
    let ctx = Context()
    let module = Module(name: "dest", in: ctx)
    let i32 = ctx.int32
    let mainType = ctx.functionType(returnType: i32)

    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(builder.buildCall(module.addFunction("helper", type: mainType), [], name: "r"))

    let source = Module(name: "src", in: ctx)
    let helper = source.addFunction("helper", type: mainType)
    let helperEntry = helper.appendBasicBlock("entry")
    builder.positionAtEnd(of: helperEntry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    try module.link(source)
    #expect(module.irString.contains("define i32 @helper()"))
    #expect(module.irString.contains("call i32 @helper"))
}

@Test func comdatAndAttribute() throws {
    let ctx = Context()
    let module = Module(name: "comdat", in: ctx)
    let i32 = ctx.int32

    let comdat = module.getOrInsertComdat("mycomdat")
    comdat.selectionKind = LLVMAnyComdatSelectionKind

    let answer = module.addGlobal("answer", type: i32)
    answer.initializer = ctx.constantInt(42, type: i32)
    answer.comdat = comdat

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    main.addAttribute(.enumAttribute(10, in: ctx), at: AttributeIndex.functionIndex)
    main.addAttribute(.stringAttribute("noinline", in: ctx), at: AttributeIndex.functionIndex)

    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let ir = module.irString
    #expect(ir.contains("$mycomdat"))
    #expect(ir.contains("noinline"))
    #expect(ir.contains("#"))

    let attrs = main.attributes(at: AttributeIndex.functionIndex)
    #expect(attrs.contains { $0.isString && $0.stringKind == "noinline" })
}

@Test func dataLayout() throws {
    let ctx = Context()
    let module = Module(name: "dl", in: ctx)
    let i32 = ctx.int32

    let dl = DataLayout(string: "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128")
    module.dataLayout = dl

    #expect(module.dataLayout.string.contains("i64:64"))
    #expect(dl.sizeOfTypeInBits(i32) == 32)
    #expect(dl.storeSizeOfType(i32) == 4)
    #expect(dl.abiSizeOfType(i32) == 4)
    #expect(dl.abiAlignmentOfType(i32) == 4)
}

@Test func debugInfoTypes() throws {
    let ctx = Context()
    let module = Module(name: "ditypes", in: ctx)

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )

    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)
    let ptrType = di.createPointerType(intType, sizeInBits: 64)
    let constType = di.createQualifiedType(tag: 0x26, type: intType)
    let typedefType = di.createTypedef(type: intType, name: "myint", file: file, line: 1, scope: cu)
    let structType = di.createStructType(
        scope: cu,
        name: "Point",
        file: file,
        line: 2,
        sizeInBits: 64,
        alignInBits: 32,
        elements: [
            di.createMemberType(
                scope: cu, name: "x", file: file, line: 2,
                sizeInBits: 32, alignInBits: 32, offsetInBits: 0, type: intType
            )
        ]
    )
    let subType = di.createSubroutineType(file: file, returnTypes: [typedefType, structType])
    let subprogram = di.createFunction(
        scope: cu, name: "main", file: file, line: 1,
        subroutineType: subType, isLocalToUnit: true, isDefinition: true, scopeLine: 1
    )

    let i32 = ctx.int32
    let mainFunc = module.addFunction("main", type: ctx.functionType(returnType: i32))
    let entry = mainFunc.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))
    mainFunc.setSubprogram(subprogram)

    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DICompileUnit"))
    #expect(ir.contains("!DIDerivedType"))
    #expect(ir.contains("!DICompositeType"))
}

@Test func verifyModule() throws {
    let ctx = Context()
    let module = Module(name: "verify", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    try module.verify()
    #expect(main.verify())
}

@Test func disassembleCode() throws {
    let triple = TargetMachine.defaultTriple
    guard let disasm = Disassembler(triple: triple) else {
        Issue.record("failed to create disassembler")
        return
    }
    let bytes: [UInt8] = [0xb8, 0x2a, 0x00, 0x00, 0x00, 0xc3]
    let instructions = disasm.disassemble(bytes)
    #expect(instructions.count == 2)
    #expect(instructions[0].contains("42") || instructions[0].contains("eax"))
    #expect(instructions[1].contains("ret"))
}

@Test func executionEngine() throws {
    let ctx = Context()
    let module = Module(name: "ee", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let ee = try ExecutionEngine(module: module)
    let result = ee.runFunction(main)?.toInt(isSigned: false) ?? 0
    #expect(result == 42)
    #expect(ee.functionAddress("main") != 0)
}

@Test func objectFileRead() throws {
    let ctx = Context()
    let module = Module(name: "obj", in: ctx)
    let i32 = ctx.int32
    let funcType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: funcType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    TargetMachine.initializeAllTargets()
    let triple = TargetMachine.defaultTriple
    let target = try Target.fromTriple(triple)
    let tm = TargetMachine(target: target, triple: triple, cpu: TargetMachine.hostCPUName)

    let tmpDir = NSTemporaryDirectory()
    let objPath = "\(tmpDir)obj_\(UUID().uuidString).o"
    try tm.emitToFile(module: module, objPath)
    defer { try? FileManager.default.removeItem(atPath: objPath) }

    let buffer = try MemoryBuffer.fromFile(objPath)
    let binary = try Binary(buffer: buffer)
    #expect(binary.type == LLVMBinaryTypeELF64L || binary.type == LLVMBinaryTypeELF64B)
    #expect(binary.sections().contains { $0.name.contains("text") })
    #expect(binary.symbols().contains { $0.name.contains("main") })
}

@Test func atomicAndAggregateInstructions() throws {
    let ctx = Context()
    let module = Module(name: "atomic", in: ctx)
    let i32 = ctx.int32
    let i64 = ctx.int64

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32, i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    let a0 = main.parameter(at: 0)
    let a1 = main.parameter(at: 1)

    let ptr = builder.buildAlloca(i32, name: "ptr")
    builder.buildStore(ctx.constantInt(0, type: i32), to: ptr)
    builder.buildFence(ordering: LLVMAtomicOrderingSequentiallyConsistent)
    let old = builder.buildAtomicRMW(
        LLVMAtomicRMWBinOpAdd, ptr, ctx.constantInt(1, type: i32),
        ordering: LLVMAtomicOrderingSequentiallyConsistent
    )
    builder.buildStore(old, to: ptr)

    let agg = ctx.constantStruct([
        ctx.constantInt(7, type: i32),
        ctx.constantInt(9, type: i64)
    ])
    let i64val = builder.buildSExt(a0, to: i64, name: "wide")
    let inserted = builder.buildInsertValue(agg, i64val, index: 1, name: "agg")
    _ = builder.buildExtractValue(inserted, index: 1, name: "val")

    let vecType = ctx.vectorType(elementType: i32, count: 4)
    let vec = ctx.undef(vecType)
    let zero = ctx.constantInt(0, type: i32)
    let insEl = builder.buildInsertElement(vec, a0, zero, name: "vec")
    let exEl = builder.buildExtractElement(insEl, a1, name: "el")
    let frozen = builder.buildFreeze(exEl, name: "frozen")

    builder.buildRet(frozen)

    let ir = module.irString
    #expect(ir.contains("fence seq_cst"))
    #expect(ir.contains("atomicrmw add"))
    #expect(ir.contains("insertvalue"))
    #expect(ir.contains("extractvalue"))
    #expect(ir.contains("insertelement"))
    #expect(ir.contains("extractelement"))
    #expect(ir.contains("freeze"))

    try module.verify()
}

@Test func debugGlobalVariable() throws {
    let ctx = Context()
    let module = Module(name: "dbgglobal", in: ctx)
    let i32 = ctx.int32

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )
    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)

    let expr = di.createExpression([])
    let gve = di.createGlobalVariableExpression(
        scope: cu,
        name: "answer",
        file: file,
        line: 1,
        type: intType,
        isLocalToUnit: true,
        expr: expr
    )

    let global = module.addGlobal("answer", type: i32)
    global.initializer = ctx.constantInt(42, type: i32)
    global.addDebugInfo(gve)

    let mainType = ctx.functionType(returnType: i32)
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)
    builder.buildRet(ctx.constantInt(42, type: i32))

    let subType = di.createSubroutineType(file: file, returnTypes: [intType])
    let subprogram = di.createFunction(
        scope: cu, name: "main", file: file, line: 1,
        subroutineType: subType, isLocalToUnit: true, isDefinition: true, scopeLine: 1
    )
    main.setSubprogram(subprogram)

    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DIGlobalVariable"))
    #expect(ir.contains("!DIGlobalVariableExpression"))
    #expect(ir.contains("!DIExpression"))
}

@Test func dbgValueRecordAndNamedMetadata() throws {
    let ctx = Context()
    let module = Module(name: "dbgval", in: ctx)
    let i32 = ctx.int32

    let di = DIBuilder(module: module)
    let file = di.createFile("test.c", directory: "/tmp")
    let cu = di.createCompileUnit(
        language: LLVMDWARFSourceLanguageC,
        file: file,
        producer: "test",
        isOptimized: false
    )
    let intType = di.createBasicType(name: "int", sizeInBits: 32, encoding: 5)

    let mainType = ctx.functionType(returnType: i32, parameterTypes: [i32])
    let main = module.addFunction("main", type: mainType)
    let entry = main.appendBasicBlock("entry")
    let builder = Builder(in: ctx)
    builder.positionAtEnd(of: entry)

    let localVar = di.createParameterVariable(
        scope: cu, name: "x", argNo: 1, file: file, line: 1, type: intType
    )
    let loc = di.createDebugLocation(line: 2, column: 3, scope: cu)
    di.insertDbgValueRecordAtEnd(
        main.parameter(at: 0),
        diVar: localVar,
        expr: di.createExpression([]),
        location: loc,
        block: entry
    )
    builder.buildRet(ctx.constantInt(42, type: i32))

    let subType = di.createSubroutineType(file: file, returnTypes: [intType])
    let subprogram = di.createFunction(
        scope: cu, name: "main", file: file, line: 1,
        subroutineType: subType, isLocalToUnit: true, isDefinition: true, scopeLine: 1
    )
    main.setSubprogram(subprogram)
    di.finalize()

    let ir = module.irString
    #expect(ir.contains("!DILocalVariable"))
    #expect(ir.contains("!DILocation"))

    module.addNamedMetadataOperand("llvm.module.flags", ctx.metadataAsValue(ctx.mdNode([])))
    #expect(module.namedMetadataOperandCount("llvm.module.flags") == 1)
    #expect(module.namedMetadataOperands("llvm.module.flags").count == 1)
    #expect(module.irString.contains("llvm.module.flags"))
}
}

