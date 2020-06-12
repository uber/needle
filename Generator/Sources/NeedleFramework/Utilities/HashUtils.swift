//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

/// Calculates the MD5 hash of the input string
func MD5(string: String) -> String {
    let length = Int(CC_MD5_DIGEST_LENGTH)
    let messageData = string.data(using:.utf8)!
    var digestData = Data(count: length)

    _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
        messageData.withUnsafeBytes { messageBytes -> UInt8 in
            if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                let messageLength = CC_LONG(messageData.count)
                CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
            }
            return 0
        }
    }
    return digestData.base64EncodedString()
}

/// Calculates the hashes of sourceFiles with the help of git
/// We use git here so that it is faster to find hashes using what git's cache
/// For changes that that untracked, we use git hash-object to calculate the hash
///
/// - parameter workingDir: The git directory where these files are located
/// - parameter sourceFileURLs: The source file whose URLs need to be computed
///
/// - returns: List of hashes sorted alphabetically based on sourceFiles
func getFileHashsUsingGit(workingDir: String, sourceFileURLs: Set<URL>) -> [String] {
    let gitURLPath = URL(fileURLWithPath: workingDir)
    let sourceFiles : [String] = sourceFileURLs.compactMap({ $0.relativePathByStrippingCommonComponents(baseURL: gitURLPath) }).sorted()
    let modifiedSwiftFiles : Set<String> = collectModifiedSwiftFiles(in: workingDir)
    let fileToFileHash = collectFileToFileHashMapping(gitDir: workingDir)
    return sourceFiles.map({ file in
        return getHashForFile(file: file, modifiedFiles: modifiedSwiftFiles, fileToFileHash: fileToFileHash, in: workingDir)
    })
}

private func getHashForFile(file: String, modifiedFiles: Set<String>, fileToFileHash: [String: String], in gitDir: String) -> String {
    // The file is modified so we should use git hash-object to generate the hash
    if modifiedFiles.contains(file) {
        return calculateHashUsingGit(gitDir: gitDir, file: file)
    } else if let hash = fileToFileHash[file] {
        return hash
    } else {
        return calculateHashUsingGit(gitDir: gitDir, file: file)
    }
}

private func collectModifiedSwiftFiles(in gitDir: String) -> Set<String> {
    let startTime = DispatchTime.now()
    let (outputOptional, status) = shell("/usr/bin/git", ["ls-files", "-m"], cwd: gitDir)
    guard let output = outputOptional, status == 0 else {
        fatalError("Could not find modified files using git ls-files command")
    }
    
    var modifiedFiles = Set<String>()
    
    for substring in output.split(separator: "\n") {
        let line = String(substring)
        if line.hasSuffix(".swift") {
            modifiedFiles.insert(line)
        }
    }
    
    let duration = (DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1000000000
    debugPrint("GOT \(modifiedFiles.count) modified files in \(duration) s")
    return modifiedFiles
}

private func calculateHashUsingGit(gitDir: String, file: String) -> String {
    let (outputOptional, status) = shell("/usr/bin/git", ["hash-object", file], cwd: gitDir)
    guard let output = outputOptional, status == 0 else {
        fatalError("Could not generate hash-object for file: \(file)")
    }

    return output
}

private func collectFileToFileHashMapping(gitDir: String) -> [String: String] {
    let startTime = DispatchTime.now()
    let (outputOptional, status) = shell("/usr/bin/git", ["ls-files", "-s", "--", "*.swift"], cwd: gitDir)
    guard let output = outputOptional, status == 0 else {
        fatalError("Could not collect hashes for files inside git directory:\(gitDir)")
    }

    var fileToHashMapping = [String:String]()

    do {
        for substring in output.split(separator: "\n") {
            let line = String(substring)
            let sections = line.split(separator: " ", maxSplits: 4, omittingEmptySubsequences: true)
            let file = String(sections[2].split(separator: "\t")[1])
            fileToHashMapping[file] = String(sections[1])
        }
    }

    let duration = (DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1000000000
    debugPrint("GOT \(fileToHashMapping.count) file hashes in \(duration) s")
    return fileToHashMapping
}

private func shell(_ launchPath: String, _ arguments: [String] = [], cwd: String) -> (String?, Int32) {
    let task = Process()
    if #available(OSX 10.13, *) {
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = arguments
        task.currentDirectoryPath = cwd
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            _ = try task.run()
        } catch {
            debugPrint("Error: \(error.localizedDescription)")
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        task.waitUntilExit()
        return (output, task.terminationStatus)
    } else {
        task.launchPath = launchPath
        task.arguments = arguments
        task.currentDirectoryPath = cwd
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        return (output, task.terminationStatus)
    }
}
