`kernel_patch_verify`
=====================

Linux kernel patch static verification helper tool

[![Kernel Patch Verify Intro video](https://img.youtube.com/vi/HzW4DrDj32w/0.jpg)](https://www.youtube.com/watch?v=HzW4DrDj32w "Kernel Patch Verify Intro video")

Background and Motivation:
==========================

This script came about as a result of various beatings I recieved and saw others
recieve in upstream kernel discussions over the last several years. Did you run
`checkpatch.pl --strict`, did you run `sparse`, is your patch series bisectable,
or the newer ones - `coccinelle` and `smatch`. I mean, why debug or even catch
these in mailing lists, if you can programmatically try to catch them up at
developer's end?

Many of these were due to:
+ Too many tools constantly evolving in linux kernel - too many goodies, and
too less time for every developer to learn
+ Having to run too many utilities using varied command lines - most normal
folks dont remember everything everytime.
+ In general, few developers are lazy, even knowing tools are not good enough
and almost everyone would like to have something quick and handy.. and if
possible, automated..

As a result, while working on "evil vendor" Android kernel as a domain
maintainer, I had originally written a dumb application called Kmake (unrelated
to the current meta build systems). This was my first attempt at automating this
entire process... and was pretty crap code and was meant for me to test 1 single
patch. It was born out of pure desperation from getting a hell lot of crap
patches from too many internal developers.

As I shared around this original code over the years, I got feedback from
various folks on varied angles:
- Dan Murphy: why cant it report required applications for it to run?
- Tero Kristo: rewrote the entire script and got me thinking along the lines of a
'patch set that needs to be applied'
- And, others who suggested tiny little things...

It was obvious, this original script needed a respin and update to newer kernel
world. So, here is another attempt with enough error handling that I could
reasonably think of in the few hours I spend rewriting... And I do not think it
is good enough yet... there are few things I dropped - storing dtbs+zImage per
patch to to allow for seperate verification by boot per patch and similar tiny
little thingies... Maybe later... I guess...

CONTRIBUTIONS:
==============

Just lets keep this on github and send pull requests to merge things up? As a
script developer, we all know that various developers have widely varying tastes.
if you feel an bug fixed or other improvements to share, send me a pull request
and we can collaborate together.

For folks wanting to write python or perl alternatives, please, go ahead and
create your own tool, just dont ask me to even touch python ;) - this remains in
bash.

QUICK START NOTES:
==================

Easiest way of getting started is to use the docker container, at least most
of the tools are pre-installed in the package (exception of gcc).

There are two scripts to use when you are in the kernel directory:

* kpv: This is a wrapper script for kernel\_patch\_verify
* kps: This drops you to the shell using the same environment that kpv runs.

You can either provide a softlink or use this git repo in your $PATH variable
to operate.

Side note: LLVM is the only pre-installed cross compiler installed in the
docker container. GCC mount paths are in kp\_common script - see function
`extra_paths` - customize it as needed for your local environment.

An trivialized example for 1 patch:

```
cd ~/src/linux
git checkout master
git pull
git checkout -b test_branch
git am ~/src/my_patches/something_patch

# do build and local functional testing - use kernel_self_test if you can..

# visually review the patch again for coding style, logic improvements etc.

# Use prepackaged LLVM to run the checks
kpv -V -C -L -n 1

# go check and identify the issues found
vim report-kernel-patch-verify.txt

# do my fixes (alternatively - i can build and check the fixups in the kps env)

# Final checkup - functional tests

# Final confirmation report checks
kpv -V -C -L -n 1

# go check and verify the issues are all closed out
vim report-kernel-patch-verify.txt

# Generate the patch
git format-patch-M -C -o . -1

# visually review the patch once again for coding style, logic improvements etc.
vim 0001-abc.patch

# run get_maintainer script to identify who to send the patch to
./scripts/get_maintainer.pl ./0001-abc.patch

# Send the patch
git send-email --to maintainer1@kernel.org --cc list@vger.kernel.org 0001-abc.patch

```

INSTALL NOTES:
==============

Almost nothing - I hope you are already using bash and building kernel -
The script should crib and provide recommendations for missing packages (or is
supposed to ;) )

For `-C` or "complete tests", the following are needed:
- smatch: (sudo apt-get install sqlite3 libsqlite3-dev llvm)

	https://blog.linuxplumbersconf.org/2011/ocw/system/presentations/165/original/transcript.txt

	https://smatch.sourceforge.net/

	NOTE for older Ubuntu installs, use: https://launchpad.net/ubuntu/+source/coccinelle

- spatch: is provided by the coccinelle package in ubuntu

:warning: **If your changes include dtb changes, then please optimize your
`.config`, since dtbscheck will take significant time!**

```
sed -n 's/^config \(ARCH.*\)/CONFIG_\1=n/p' arch/arm64/Kconfig.platforms | grep -v K3 >> .config
```

Usage:
======

```
./kernel_patch_verify [-d] [-j CPUs] [-B build_target] [-T tmp_dir_base] [-l logfile] [-C] [-c defconfig_name] [-1]|[-p patch_dir]|[-b base_branch [-t head_branch]]
	-d: if not already defined, use CROSS_COMPILE=arm-linux-gnueabi-, ARCH=arm, and builds for ' zImage dtbs' build targets
	-j CPUs: override default CPUs count with build (default is 4)
	-B build_target: override default build target and use provided build_target
	-T temp_dir_base: temporary directory base (default is /tmp)
	-l logfile: report file (defaults to ./report-kernel-patch-verify.txt)
	-C: run Complete tests(WARNING: could take significant time!)
	-c defconfig:_name (default uses current .config + oldconfig)
	-1: test the tip of current branch (just a single patch)
	-p patch_dir: which directory to take patches from (expects sorted in order)
	-b base_branch: test patches from base_branch
	-t test_branch: optionally used with -b, till head branch, if not provided, along with -b, default will be tip of current branch

```

NOTE:
* Only one of -1, -p or (-b,-t) should be used - but at least one of these should be used
* Cannot have a diff pending OR be on a dangling branch `base_branch` should exist as well
* The default tests are selected with view of as minimal time as possible, while the `-C` tests
are the comprehensive tests which are strongly recommended before showing your patches to any other
human being.

Example usages:
===============

* Verify last commmitted patch:

    ```
    ./kernel_patch_verify -1
    ```

* Verify on top of current branch patches from location `~/tmp/test-patches`:

    ```
    ./kernel_patch_verify -p ~/tmp/test-patches
    ```

* Verify *from* branch `base_branch` till current branch:

    ```
    ./kernel_patch_verify -b base_branch
    ```

* Verify all patches *from* current branch *until* `test_branch`:

    ```
    ./kernel_patch_verify -t test_branch
    ```

* Verify all patches *from* `base_branch` *until* `test_branch`:

    ```
    ./kernel_patch_verify -b base_branch -t test_branch
    ```

* Verify, with complete tests, all patches *from* `base_branch` *until*
  `test_branch`:

    ```
    ./kernel_patch_verify -b base_branch -t test_branch -C
    ```

* Verify last committed patch on a native x86 build using `make`, `gcc`, and the
  `bzImage` target:

    ```
    ./kernel_patch_verify -B bzImage -1
    ```

* Verify last committed patch on a cross-compiled ARM build using defaults:

    ```
    ./kernel_patch_verify -d -1
    ```

Notes on AI-assisted review
============================

AI Review with Claude
---------------------

The tool supports AI-powered patch review using Claude and the `review-prompts`
framework. This provides intelligent, context-aware reviews of complete patch series.

To use this feature:
1. Install Claude Code: https://code.claude.com/docs/en/setup
2. Install review-prompts: https://github.com/masoncl/review-prompts
3. Use the `-A` option to enable AI review

Example:
```bash
# Review the last patch with AI
kpv -V -L -A -1

# Review a complete series with AI
kpv -V -L -A -b base_branch -t test_branch
```

### Semcode Integration

The AI review works best with semcode indexing, which provides better context
about the codebase. The tool will automatically use semcode if available.

To install semcode: https://github.com/facebookexperimental/semcode


You can optimize semcode database reuse by setting the `SEMCODE_DB` environment
variable in your `~/.bashrc`:

```bash
export SEMCODE_DB=/path/to/shared/semcode-db
```

When set, the tool will create a softlink from `.semcode.db` in your kernel
directory to the shared database, allowing multiple kernel trees to share the
same semcode index.

### Lore Mailing List Integration

When using AI review with semcode, you can specify which kernel mailing lists
to index for additional context using the `-M` option:

```bash
# Custom lore mailing lists
kpv -A -M linux-arm-kernel,lkml/0 -1

# Skip lore indexing (useful for repeated runs after initial indexing)
kpv -A -M "" -1
```

Default lists indexed: `linux-arm-kernel,linux-devicetree,linux-clk,linux-pm,netdev,dri-devel`

**Optimization tip:** Lore mailing list indexing only needs to run once to populate
the semcode database. For subsequent runs on the same codebase, you can use `-M ""`
to skip lore indexing and speed up the review process, as the mailing list context
is already available in the database.

**Warning:** Do not use `-M ""` if there have been recent relevant discussions on
the mailing lists related to your changes. Re-indexing ensures the AI has access
to the latest conversations, bug reports, and feedback that might be relevant to
your patch review.

Notes on patchwise
==================

Qualcomm released https://github.com/qualcomm/PatchWise which is an awesome tool
to get some basic automated reviews of the patches done prior to maintainers or
other reviewers reviewing stuff.

To use this use the `-P` option. This requires at least `OPENAI_API_KEY` variable
to be defined, however, you may also use the additional optional variables:
* `OPENAI_API_MODEL` point to appropriate model you'd like to use.
* `OPENAI_API_PROVIDER` if your company uses llm gateways of any form

This test can execute multiple tests already performed, but it is just additional
review tool that is available. Expect to see some significant time spend in this
check.

Some script design stuff:
=========================

Alright, the shell script should be readable in it's own I hope... anyways,
tests are organized as:
* `ptest_xyz` -> these tests take the patch as the argument
* `ftest_xyz` -> these tests take c file (impacted by the patch) as the argument
* `btest_xyz` -> there are of two types: the ones that take .o files as arguments
and those that build the entire kernel

Tests are organized per patch OR overall (basically run before the patch series
and after the patch series). Reports are generated after all the tests are run,
I have not tried to standardize the reports in any way, except that if there is
a 'change' in log, for example:
* A build warning was created with a patch.
* A build warning was removed with a patch in the series.

This will appear as a a diff (both build warning was removed or added is
considered similar) and that diff is provided in the report log. the final report
log is a consolidation of every single patch, over all results and also provides
information about the tools and versions used.

Without the `-C` switch, only tests that take a short amount of time will be
ran. Tests that take significant time should be listed under `-C`. I recommend
reading the code to see the list of tests executed. This will also be printed as
you execute the tests. Just remember that false positives are irritable to
developers, so be careful of the results.

The generic strategy for the test is that everything in stderr is logged, a test
should never throw anything on stdout as it just craps up the developer's screen.
If a test provides result on stdout, redirect it to stderr. Pass/fail criteria is
as follows:
* For `ftest_`, `btest_`, the before and after logs should show 0 diff. If there
  are, it assumes new fail introduction
* For `ptest`, no output is a pass, any output tends to be a fail.


Author and versioning highlights (chronological):
-------------------------------------------------
* Nishanth Menon Dec 2013, Dallas, TX, while lying in bed with a slight migraine
staring at a cloudy sky and spewing nonsense into vim... and guessing that no one
might even care about this...
