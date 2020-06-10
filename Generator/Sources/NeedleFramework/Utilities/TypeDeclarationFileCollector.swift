import Foundation

public func collectFileToFileHashMapping(gitDir: String) -> [String: String] {
    let startTime = DispatchTime.now()
    let (outputOptional, status) = shell("/usr/bin/git", ["ls-files", "-s", "--", "*.swift"], cwd: gitDir)
    guard status == 0 else {
        return [:]
    }
    guard let output = outputOptional else {
        return [:]
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

    //TODO: Collect hashes for untracked changes or
    //Or may be we should directly execute "git hash-object" if they are a part of the DependencyFiles?

    let duration = (DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1000000000
    print("GOT \(fileToHashMapping.count) file hashes in \(duration) s")
    return fileToHashMapping

}

public func collectTypeToTypeDeclarationFileMapping(gitDir: String) -> [String: Set<String>] {

    let startTime = DispatchTime.now()

    let (outputOptional, status) = shell("/usr/bin/git", ["grep", "-E", "(struct|class|protocol|enum)", "--", "*.swift"], cwd: gitDir)
    guard status == 0 else {
        return [:]
    }
    guard let output = outputOptional else {
        return [:]
    }


    var typeToFileNameMapping = [String:Set<String>]()

    do {
        let regexPattern = try NSRegularExpression(pattern: "^(.*):.*(struct|class|protocol|enum) ([a-zA-Z_0-9]+)(: )?.*$", options: [])
        for substring in output.split(separator: "\n") {
            let line = String(substring)
            let result = regexPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count))
            if let match = result {
                let filename = line.substring(with: match.range(at: 1))!
                let type = line.substring(with: match.range(at: 3))!
                if typeToFileNameMapping[type] == nil {
                    typeToFileNameMapping[type] = [filename]
                } else {
                    typeToFileNameMapping[type]?.insert(filename)
                }

            }
        }
    } catch {
        print("ERROR IN REGEX")
    }
    let duration = (DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1000000000
    print("GOT \(typeToFileNameMapping.count) types in \(duration) s" )

    return typeToFileNameMapping
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
            print("Error: \(error.localizedDescription)")
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        task.waitUntilExit()
        return (output, task.terminationStatus)
    } else {
        return ("NOT SUPPORTED", 1)
    }
}
