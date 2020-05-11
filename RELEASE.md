# Publishing a New Release
*This page contains instructions for admins of this project to release a new version.*

## Run Makefile
Run `$ make publish VERSION_NUMBER` at the root directory of needle (where the `Makefile` is located)

For example:
```
$ make publish 0.13.0
```

This runs the steps specified in the `Makefile`.

The `Makefile` does not support failure recovery yet. If a certain step fails, you need to resolve it and manually run the remaining steps.

## Create a new Github release
After all the steps in the `Makefile` finish successfully, go to the Releases tab and create a new release.
