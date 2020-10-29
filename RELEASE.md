# Publishing a New Release
*This page contains instructions for admins of this project to release a new version.*

## Run Makefile
1. Run `$ make release VERSION_NUMBER` at the root directory of needle (where the `Makefile` is located)

    For example:
    ```
    $ make release 0.13.0
    ```

2. Run `$ make publish` to publish the release to various destinations (like CocoaPods and Homebrew).

## Create a new Github release
After all the steps in the `Makefile` finish successfully, go to the Releases tab and create a new release.
