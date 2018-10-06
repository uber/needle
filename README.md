# needle

Needle is a dependency injection system for Swift iOS apps. It utilizes code generation to ensure compile-time safey. If it compiles, it works.

Needle is currently in pre-release mode. We (Uber) are migrating all of our apps to Needle, therefore we haven't had the chance to finish the documentation. If you want to explore yourself feel free to use the following crude guide:

1. Download the NeedleFoundation release from the Releases tab and include the source into your project.
2. Follow the sample projects to create components and dependency protocols.
3. Build a release version of Generator by running this command from the Generator folder of this repo `swift build -c release -Xswiftc -static-stdlib`.
4. Invoke the resulting binary this command: `needle generate "GENERATED_CODE_OUTPUT_FILE_PATH" "ROOT_FOLDER_OF_YOUR_PROJECT_SWIFT_SOURCE_FILES" --additional-imports "import YOUR_ROOT_MODULE" --header-doc "PATH_TO_A_TXT_HEADER_DOC_FILE" --exclude-suffixes Tests --exclude-paths "ANY_SUBFOLDERS_YOU_DO_NOT_WANT_TO_PARSE"`
5. Make sure the generated code file is included in your project.
6. Invoke `registerProviderFactories()` in your `main.swift` or `AppDelegate` as the first line of code to execute.

After you update DI code, just re-run step 4 and everything should be good.

## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency?ref=badge_large)
