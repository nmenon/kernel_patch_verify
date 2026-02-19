# CLAUDE.md - Guide for Updating Files in kernel_patch_verify

This document provides guidance for AI assistants (like Claude) and developers when updating files in this repository.

## Repository Overview

`kernel_patch_verify` is a Linux kernel patch static verification helper tool written in bash. It automates running multiple kernel verification tools (checkpatch, sparse, smatch, coccinelle, etc.) against kernel patches to catch issues before submission to upstream.

## Key Files and Their Purposes

### Core Scripts

- **kernel_patch_verify** - Main verification script (bash)
  - Contains test functions organized as `ptest_*`, `ftest_*`, and `btest_*`
  - Coordinates execution of all verification tools
  - Generates consolidated report of findings

- **kp_common** - Common functions and configurations
  - Shared utilities used by other scripts
  - Path configurations for cross-compilers

- **kpv** - Docker wrapper script
  - Executes `kernel_patch_verify` inside Docker container
  - Handles volume mounts and environment setup

- **kps** - Shell entry script
  - Drops user into shell with same environment as kpv

### Build Environment

- **Dockerfile** - Docker image definition
  - Installs verification tools (sparse, coccinelle, smatch, etc.)
  - Sets up build environment

- **build-env.sh** - Build environment setup script
  - Downloads and installs verification tools
  - Configures tool versions and dependencies

### Configuration

- **other-configs/** - Additional configurations
  - Contains config files for various tools
  - Mounted into Docker environment

### Documentation

- **README.md** - User-facing documentation
- **Dockerbuild.md** - Docker build instructions
- **CLAUDE.md** - This file

## Guidelines for Updating Files

### Updating kernel_patch_verify

When modifying the main verification script:

1. **Test Organization**
   - `ptest_*` functions: Test patches (take patch file as argument)
   - `ftest_*` functions: Test C files impacted by patch
   - `btest_*` functions: Build tests (take .o files or build entire kernel)

2. **Test Criteria**
   - Fast tests: Run by default (no `-C` flag needed)
   - Comprehensive tests: Run with `-C` flag (may take significant time)
   - Tests should output to stderr, not stdout
   - Pass/fail: For f/btest, before/after logs should show 0 diff; for ptest, no output = pass

3. **Error Handling**
   - Always check for tool availability before use
   - Provide helpful error messages about missing dependencies
   - Follow existing error reporting patterns

4. **Compatibility**
   - Maintain bash compatibility (no python/perl)
   - Support both native and cross-compilation scenarios
   - Test with both Docker and native environments

5. **Code Style**
   - Follow existing bash style conventions
   - Use meaningful variable names
   - Add comments for non-obvious logic
   - Keep functions focused and single-purpose

### Updating Build Environment

When modifying Dockerfile or build-env.sh:

1. **Tool Versions**
   - Update version numbers in `build-env.sh`
   - Document version changes in commit messages
   - Test that new versions don't break existing workflows

2. **Dependencies**
   - Keep base image minimal
   - Document any new apt packages needed
   - Verify cross-compiler compatibility

3. **Size Considerations**
   - Avoid including GCC toolchains in image (mount from host)
   - Clean up build artifacts to minimize image size

### Updating Configuration Files

When modifying files in other-configs/:

1. **Tool Configs**
   - Test configuration changes with actual kernel code
   - Document non-obvious config options
   - Ensure configs work in both Docker and native environments

### Updating Documentation

When modifying README.md or Dockerbuild.md:

1. **Keep Examples Current**
   - Test example commands before documenting
   - Include expected output when helpful
   - Update examples if script options change

2. **Maintain Structure**
   - Follow existing documentation organization
   - Use clear section headings
   - Keep quick-start section concise

3. **Document New Features**
   - Add usage examples for new options
   - Explain when to use new features
   - Document any new dependencies

## Testing Changes

Before committing changes:

1. **Functional Testing**
   - Test with actual kernel patches
   - Try both quick (`-1`) and comprehensive (`-C`) modes
   - Test in Docker environment using `kpv`
   - Verify report generation

2. **Environment Testing**
   - Test with clean Docker container
   - Test native execution if applicable
   - Verify cross-compilation scenarios work

3. **Edge Cases**
   - Test with single patch and patch series
   - Test with patches that have known issues
   - Verify error handling for missing tools

## Common Update Scenarios

### Adding a New Verification Tool

1. Add tool installation to `build-env.sh` or Dockerfile
2. Create test function in `kernel_patch_verify` (ptest/ftest/btest)
3. Add tool detection and error messaging
4. Decide if tool is fast (default) or comprehensive (`-C`)
5. Update README.md with new tool info
6. Test thoroughly

### Updating Tool Versions

1. Modify version in `build-env.sh`
2. Rebuild Docker image: `make clean && make`
3. Test with known good patches
4. Check for behavior changes in tool output
5. Update documentation if needed

### Modifying Report Format

1. Update report generation in `kernel_patch_verify`
2. Test report output with various scenarios
3. Ensure backward compatibility if others parse reports
4. Document format changes

### Adding Script Options

1. Update getopts section in `kernel_patch_verify`
2. Add option handling logic
3. Update usage message
4. Update README.md examples
5. Test new option with other options

## Contribution Guidelines

From the README:

- Keep this tool in bash (no python/perl alternatives)
- Send pull requests via GitHub
- Focus on practical utility for kernel developers
- Avoid false positives that irritate developers
- Test changes before submitting

## Notes

- This tool is meant to catch issues before kernel maintainer review
- Speed matters - developers won't use slow tools
- False positives are worse than false negatives
- The tool should never throw errors on stdout (use stderr)
- Cross-platform support (native x86, ARM cross-compile, etc.) is important

## Contact

For bugs or improvements, submit issues at:
https://github.com/nmenon/kernel_patch_verify/issues
