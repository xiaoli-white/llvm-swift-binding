import Testing
import Foundation
import cLLVM
@testable import LLVMSwiftBinding

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
