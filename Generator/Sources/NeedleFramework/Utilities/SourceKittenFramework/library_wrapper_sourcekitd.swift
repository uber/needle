//  Copied from SourceKittenFramework library_wrapper.swift [https://github.com/jpsim/SourceKitten/blob/master/Source/SourceKittenFramework/library_wrapper_sourcekitd.swift]
//
//  library_wrapper.swift
//  sourcekitten
//
//  Created by Norio Nomura on 2/20/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

#if os(Linux)
private let path = "libsourcekitdInProc.so"
#else
private let path = "sourcekitd.framework/Versions/A/sourcekitd"
#endif
private let library = toolchainLoader.load(path: path)
internal let sourcekitd_initialize: @convention(c) () -> () = library.load(symbol: "sourcekitd_initialize")
