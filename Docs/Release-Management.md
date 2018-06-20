# ComputeFramework release management

## Versioning
Try to follow [Semantic Versioning 2.0.0](http://semver.org/) documentation for versioning.

## Release workflow
### Release candidate
1. Use `development` branch for release candidate. If developer merged code to `development` and it is time to do release candidate package, developer has to create the tag with the following format `v{MAJOR}.{MINOR}.{PATCH}rc-1` for the last commit to the branch. 
1. If it is required doing more work after step 1 in `development` branch, work should be implemented and after it merged to branch and new tag with incremented release candidate number should be created, e.g. `v3.1.0rc-2`, `v3.1.0rc-3` ... .

### Release
1. Use `master` branch for releases. 
1. Do not merge code to `master` branch (create release), until it properly tested on `development` branch.
1. The release should be tagged with the tag with the following format `v{MAJOR}.{MINOR}.{PATCH}` after properly tested code merged to `master` branch.
1. If it is necessary to do any hot-fix on `master` branch, after implementation branch should be tagged with the tag with incremented `{PATCH}`, e.g `v3.1.1`, `v3.1.2` ... .

## GitHub release structure 
1. The release should have appropriate name with the following format: `ComputeFramework-v{MAJOR}.{MINOR}.{PATCH}`, e.g. `ComputeFramework v3.1.0`
   1. The name could contain `rc-{number}` postfix, which tells that it is release candidate package, e.g. `ComputeFramework v3.1.0rc-1`.
   1. If release candidate, then `This is a pre-release` option should be checked.
1. The release should contain git tag which refers to framework version. Tag format: `v{MAJOR}.{MINOR}.{PATCH}` e.g. `v3.1.0`.
1. The release should contain all supported OS (Windows, Linux) binaries.
1. Linux and Windows binaries should be uploaded as separate zip files.

### Windows binaries
1. Binaries should be compressed to zip archive with name with the following format: `ComputeFramework-Win-v{MAJOR}.{MINOR}.{PATCH}.zip`, e.g. `ComputeFramework-Win-v3.1.0.zip`
   1. Zip-archive could contain `rc-{number}` postfix, e.g `ComputeFramework-Win-v3.1.0rc-1.zip`.
1. Zip-archive should contain compiled ComputeFramework for **Matlab Runtime 9.1** for Windows.
1. Create file `version.txt` with git tag as content. 
1. List of files in archive:
   * ComputeFramework.exe (required)
   * version.txt (required)
   * splash.png (optional)
   * readme.txt (optional)
   * icon.ico (optional)

### Linux binaries
1. Binaries should be compressed to zip archive with name with the following format: `ComputeFramework-Linux-v{MAJOR}.{MINOR}.{PATCH}.zip`, e.g. `ComputeFramework-Linux-v3.1.0.zip`.
    1. Zip-archive could contain `rc-{number}` postfix, e.g. `ComputeFramework-Linux-v3.1.0rc-1.zip`.
1. Zip-archive should contain compiled ComputeFramework for **Matlab Runtime 9.1** for Linux (Ubuntu 16.04).
1. Create file `version.txt` with git tag as content. 
1. List of files in archive:
   * ComputeFramework (required)
   * run_ComputeFramework.sh (required)
   * version.txt (required)
   * splash.png (optional)
   * readme.txt (optional)
