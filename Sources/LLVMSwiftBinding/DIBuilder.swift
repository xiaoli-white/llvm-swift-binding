import cLLVM

public final class DIBuilder {
    public let ref: LLVMDIBuilderRef
    public let module: Module

    public init(module: Module) {
        ref = LLVMCreateDIBuilder(module.ref)
        self.module = module
    }

    deinit {
        LLVMDisposeDIBuilder(ref)
    }

    public func finalize() {
        LLVMDIBuilderFinalize(ref)
    }

    public func finalizeSubprogram(_ subprogram: Metadata) {
        LLVMDIBuilderFinalizeSubprogram(ref, subprogram.ref)
    }

    public func createFile(_ filename: String, directory: String) -> Metadata {
        let metaRef = filename.withCString { filenamePtr in
            directory.withCString { dirPtr in
                LLVMDIBuilderCreateFile(ref, filenamePtr, filename.utf8.count, dirPtr, directory.utf8.count)
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createCompileUnit(language: LLVMDWARFSourceLanguage,
                                  file: Metadata,
                                  producer: String,
                                  isOptimized: Bool = false,
                                  flags: String = "",
                                  runtimeVersion: UInt32 = 0,
                                  emissionKind: LLVMDWARFEmissionKind = LLVMDWARFEmissionFull,
                                  splitDebugInlining: Bool = true) -> Metadata
    {
        let metaRef = producer.withCString { producerPtr in
            flags.withCString { flagsPtr in
                LLVMDIBuilderCreateCompileUnit(
                    ref, language, file.ref,
                    producerPtr, producer.utf8.count,
                    isOptimized ? 1 : 0,
                    flagsPtr, flags.utf8.count,
                    runtimeVersion,
                    "", 0,
                    emissionKind, 0,
                    splitDebugInlining ? 1 : 0,
                    0, "", 0, "", 0
                )
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createSubroutineType(file: Metadata, returnTypes: [Metadata] = []) -> Metadata {
        var types: [LLVMMetadataRef?] = returnTypes.map(\.ref)
        let metaRef = types.withUnsafeMutableBufferPointer { buffer in
            LLVMDIBuilderCreateSubroutineType(
                ref, file.ref, buffer.baseAddress,
                UInt32(returnTypes.count), LLVMDIFlagZero
            )
        }
        return Metadata(ref: metaRef!)
    }

    public func createFunction(scope: Metadata,
                               name: String,
                               linkageName: String = "",
                               file: Metadata,
                               line: UInt32,
                               subroutineType: Metadata,
                               isLocalToUnit: Bool = true,
                               isDefinition: Bool = true,
                               scopeLine: UInt32 = 0,
                               flags: LLVMDIFlags = LLVMDIFlagZero,
                               isOptimized: Bool = false) -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            linkageName.withCString { linkagePtr in
                LLVMDIBuilderCreateFunction(
                    ref, scope.ref,
                    namePtr, name.utf8.count,
                    linkagePtr, linkageName.utf8.count,
                    file.ref, line, subroutineType.ref,
                    isLocalToUnit ? 1 : 0, isDefinition ? 1 : 0,
                    scopeLine, flags, isOptimized ? 1 : 0
                )
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createLexicalBlock(scope: Metadata, file: Metadata, line: UInt32, column: UInt32) -> Metadata {
        let metaRef = LLVMDIBuilderCreateLexicalBlock(ref, scope.ref, file.ref, line, column)
        return Metadata(ref: metaRef!)
    }

    public func createDebugLocation(line: UInt32, column: UInt32, scope: Metadata,
                                    inlinedAt: Metadata? = nil) -> Metadata
    {
        let metaRef = LLVMDIBuilderCreateDebugLocation(
            module.context.ref, line, column, scope.ref, inlinedAt?.ref
        )
        return Metadata(ref: metaRef!)
    }

    public func createBasicType(
        name: String,
        sizeInBits: UInt64,
        encoding: LLVMDWARFTypeEncoding,
        flags: LLVMDIFlags = LLVMDIFlagZero
    ) -> Metadata {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateBasicType(ref, namePtr, name.utf8.count, sizeInBits, encoding, flags)
        }
        return Metadata(ref: metaRef!)
    }

    public func createParameterVariable(scope: Metadata,
                                        name: String,
                                        argNo: UInt32,
                                        file: Metadata,
                                        line: UInt32,
                                        type: Metadata,
                                        alwaysPreserve: Bool = false,
                                        flags: LLVMDIFlags = LLVMDIFlagZero) -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateParameterVariable(
                ref, scope.ref, namePtr, name.utf8.count,
                argNo, file.ref, line, type.ref,
                alwaysPreserve ? 1 : 0, flags
            )
        }
        return Metadata(ref: metaRef!)
    }

    public func createAutoVariable(scope: Metadata,
                                   name: String,
                                   file: Metadata,
                                   line: UInt32,
                                   type: Metadata,
                                   alwaysPreserve: Bool = false,
                                   flags: LLVMDIFlags = LLVMDIFlagZero,
                                   alignInBits: UInt32 = 0) -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateAutoVariable(
                ref, scope.ref, namePtr, name.utf8.count,
                file.ref, line, type.ref,
                alwaysPreserve ? 1 : 0, flags, alignInBits
            )
        }
        return Metadata(ref: metaRef!)
    }

    public func insertDeclareAtEnd(
        _ value: Value,
        diVar: Metadata,
        expr: Metadata,
        location: Metadata,
        block: BasicBlock
    ) {
        LLVMDIBuilderInsertDeclareRecordAtEnd(
            ref, value.ref, diVar.ref, expr.ref, location.ref, block.ref
        )
    }

    public func createPointerType(_ pointee: Metadata,
                                  sizeInBits: UInt64,
                                  alignInBits: UInt32 = 0,
                                  addressSpace: UInt32 = 0,
                                  name: String = "") -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreatePointerType(
                ref, pointee.ref, sizeInBits, alignInBits, addressSpace, namePtr, name.utf8.count
            )
        }
        return Metadata(ref: metaRef!)
    }

    public func createQualifiedType(tag: UInt32, type: Metadata) -> Metadata {
        let metaRef = LLVMDIBuilderCreateQualifiedType(ref, tag, type.ref)
        return Metadata(ref: metaRef!)
    }

    public func createNullPtrType() -> Metadata {
        let metaRef = LLVMDIBuilderCreateNullPtrType(ref)
        return Metadata(ref: metaRef!)
    }

    public func createTypedef(type: Metadata,
                              name: String,
                              file: Metadata,
                              line: UInt32,
                              scope: Metadata,
                              alignInBits: UInt32 = 0) -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateTypedef(
                ref, type.ref, namePtr, name.utf8.count, file.ref, line, scope.ref, alignInBits
            )
        }
        return Metadata(ref: metaRef!)
    }

    public func createStructType(scope: Metadata,
                                 name: String,
                                 file: Metadata,
                                 line: UInt32,
                                 sizeInBits: UInt64,
                                 alignInBits: UInt32,
                                 flags: LLVMDIFlags = LLVMDIFlagZero,
                                 derivedFrom: Metadata? = nil,
                                 elements: [Metadata] = []) -> Metadata
    {
        var elems: [LLVMMetadataRef?] = elements.map(\.ref)
        let metaRef = name.withCString { namePtr in
            elems.withUnsafeMutableBufferPointer { buffer in
                LLVMDIBuilderCreateStructType(
                    ref, scope.ref, namePtr, name.utf8.count, file.ref, line,
                    sizeInBits, alignInBits, flags, derivedFrom?.ref,
                    buffer.baseAddress, UInt32(elements.count), 0, nil, "", 0
                )
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createMemberType(scope: Metadata,
                                 name: String,
                                 file: Metadata,
                                 line: UInt32,
                                 sizeInBits: UInt64,
                                 alignInBits: UInt32,
                                 offsetInBits: UInt64,
                                 flags: LLVMDIFlags = LLVMDIFlagZero,
                                 type: Metadata) -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateMemberType(
                ref, scope.ref, namePtr, name.utf8.count, file.ref, line,
                sizeInBits, alignInBits, offsetInBits, flags, type.ref
            )
        }
        return Metadata(ref: metaRef!)
    }

    public func createArrayType(size: UInt64,
                                alignInBits: UInt32,
                                elementType: Metadata,
                                subscripts: [Metadata]) -> Metadata
    {
        var subs: [LLVMMetadataRef?] = subscripts.map(\.ref)
        let metaRef = subs.withUnsafeMutableBufferPointer { buffer in
            LLVMDIBuilderCreateArrayType(
                ref, size, alignInBits, elementType.ref, buffer.baseAddress, UInt32(subscripts.count)
            )
        }
        return Metadata(ref: metaRef!)
    }

    public func createUnionType(scope: Metadata,
                                name: String,
                                file: Metadata,
                                line: UInt32,
                                sizeInBits: UInt64,
                                alignInBits: UInt32,
                                flags: LLVMDIFlags = LLVMDIFlagZero,
                                elements: [Metadata] = []) -> Metadata
    {
        var elems: [LLVMMetadataRef?] = elements.map(\.ref)
        let metaRef = name.withCString { namePtr in
            elems.withUnsafeMutableBufferPointer { buffer in
                LLVMDIBuilderCreateUnionType(
                    ref, scope.ref, namePtr, name.utf8.count, file.ref, line,
                    sizeInBits, alignInBits, flags, buffer.baseAddress,
                    UInt32(elements.count), 0, "", 0
                )
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createForwardDecl(tag: UInt32,
                                  name: String,
                                  scope: Metadata,
                                  file: Metadata,
                                  line: UInt32,
                                  sizeInBits: UInt64 = 0,
                                  alignInBits: UInt32 = 0,
                                  uniqueIdentifier: String = "") -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            uniqueIdentifier.withCString { uniquePtr in
                LLVMDIBuilderCreateForwardDecl(
                    ref, tag, namePtr, name.utf8.count, scope.ref, file.ref, line,
                    0, sizeInBits, alignInBits, uniquePtr, uniqueIdentifier.utf8.count
                )
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createUnspecifiedType(_ name: String) -> Metadata {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateUnspecifiedType(ref, namePtr, name.utf8.count)
        }
        return Metadata(ref: metaRef!)
    }

    public func createExpression(_ ops: [UInt64]) -> Metadata {
        var ops = ops
        let metaRef = ops.withUnsafeMutableBufferPointer { buffer in
            LLVMDIBuilderCreateExpression(ref, buffer.baseAddress, buffer.count)
        }
        return Metadata(ref: metaRef!)
    }

    public func createConstantValueExpression(_ value: UInt64) -> Metadata {
        let metaRef = LLVMDIBuilderCreateConstantValueExpression(ref, value)
        return Metadata(ref: metaRef!)
    }

    public func getOrCreateArray(_ elements: [Metadata]) -> Metadata {
        var elems: [LLVMMetadataRef?] = elements.map(\.ref)
        let metaRef = elems.withUnsafeMutableBufferPointer { buffer in
            LLVMDIBuilderGetOrCreateArray(ref, buffer.baseAddress, buffer.count)
        }
        return Metadata(ref: metaRef!)
    }

    public func getOrCreateSubrange(lowerBound: Int64, count: Int64) -> Metadata {
        let metaRef = LLVMDIBuilderGetOrCreateSubrange(ref, lowerBound, count)
        return Metadata(ref: metaRef!)
    }

    public func createGlobalVariableExpression(scope: Metadata,
                                               name: String,
                                               linkageName: String = "",
                                               file: Metadata,
                                               line: UInt32,
                                               type: Metadata,
                                               isLocalToUnit: Bool = true,
                                               expr: Metadata,
                                               decl: Metadata? = nil,
                                               alignInBits: UInt32 = 0) -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            linkageName.withCString { linkagePtr in
                LLVMDIBuilderCreateGlobalVariableExpression(
                    ref, scope.ref,
                    namePtr, name.utf8.count,
                    linkagePtr, linkageName.utf8.count,
                    file.ref, line, type.ref,
                    isLocalToUnit ? 1 : 0,
                    expr.ref, decl?.ref, alignInBits
                )
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func insertDbgValueRecordAtEnd(_ value: Value,
                                          diVar: Metadata,
                                          expr: Metadata,
                                          location: Metadata,
                                          block: BasicBlock)
    {
        LLVMDIBuilderInsertDbgValueRecordAtEnd(
            ref, value.ref, diVar.ref, expr.ref, location.ref, block.ref
        )
    }

    public func createModule(scope: Metadata,
                             name: String,
                             configMacros: String = "",
                             includePath: String = "",
                             apiNotesFile: String = "") -> Metadata
    {
        let metaRef = name.withCString { namePtr in
            configMacros.withCString { macrosPtr in
                includePath.withCString { includePtr in
                    apiNotesFile.withCString { apiPtr in
                        LLVMDIBuilderCreateModule(
                            ref, scope.ref,
                            namePtr, name.utf8.count,
                            macrosPtr, configMacros.utf8.count,
                            includePtr, includePath.utf8.count,
                            apiPtr, apiNotesFile.utf8.count
                        )
                    }
                }
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createNameSpace(scope: Metadata, name: String, exportSymbols: Bool = false) -> Metadata {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateNameSpace(ref, scope.ref, namePtr, name.utf8.count, exportSymbols ? 1 : 0)
        }
        return Metadata(ref: metaRef!)
    }

    public func createEnumerator(name: String, value: Int64, isUnsigned: Bool = false) -> Metadata {
        let metaRef = name.withCString { namePtr in
            LLVMDIBuilderCreateEnumerator(ref, namePtr, name.utf8.count, value, isUnsigned ? 1 : 0)
        }
        return Metadata(ref: metaRef!)
    }

    public func createEnumerationType(scope: Metadata,
                                      name: String,
                                      file: Metadata,
                                      line: UInt32,
                                      sizeInBits: UInt64,
                                      alignInBits: UInt32,
                                      elements: [Metadata],
                                      classType: Metadata? = nil) -> Metadata
    {
        var elems: [LLVMMetadataRef?] = elements.map(\.ref)
        let metaRef = name.withCString { namePtr in
            elems.withUnsafeMutableBufferPointer { buffer in
                LLVMDIBuilderCreateEnumerationType(
                    ref, scope.ref, namePtr, name.utf8.count,
                    file.ref, line, sizeInBits, alignInBits,
                    buffer.baseAddress, UInt32(elements.count), classType?.ref
                )
            }
        }
        return Metadata(ref: metaRef!)
    }

    public func createLexicalBlockFile(scope: Metadata, file: Metadata, discriminator: UInt32) -> Metadata {
        let metaRef = LLVMDIBuilderCreateLexicalBlockFile(ref, scope.ref, file.ref, discriminator)
        return Metadata(ref: metaRef!)
    }

    public func createImportedModuleFromNamespace(scope: Metadata, namespace: Metadata, file: Metadata,
                                                  line: UInt32) -> Metadata
    {
        let metaRef = LLVMDIBuilderCreateImportedModuleFromNamespace(ref, scope.ref, namespace.ref, file.ref, line)
        return Metadata(ref: metaRef!)
    }
}

public final class Metadata {
    public let ref: LLVMMetadataRef

    public init(ref: LLVMMetadataRef) {
        self.ref = ref
    }

    public var tag: UInt16 {
        LLVMGetDINodeTag(ref)
    }

    public var kind: LLVMMetadataKind {
        LLVMGetMetadataKind(ref)
    }
}
