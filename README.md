kernel_patch_verify
===================

Linux kernel patch static verification helper tool

Background and Motivation:
=========================

This script came about as a result of various beatings I recieved and saw others
recieve in upstream kernel discussions over the last several years.
Did you run 'checkpatch.pl --strict', did you run sparse, is your patch series
bisectable, or the newer ones - coccinelle, smatch. I mean, why debug or even
catch these in mailing lists, if you can programmatically try to catch them up
at developer's end?

Many of these were due to:
+ Too many tools constantly evolving in linux kernel - too many goodies, and
too less time for every developer to learn
+ Having to run too many utilities using varied command lines - most normal
folks dont remember everything everytime.
+ In general, few developers are lazy, even knowing tools are not good enough
and almost everyone would like to have something quick and handy.. and if
possible, automated..

As a result, while working on "evil vendor" Android kernel as a domain
maintainer, I had originally written a dumb application called Kmake
(http://www.omappedia.com/wiki/Kmake). This was my first attempt at automating
this entire process..  and was pretty crap code and was meant for me to test 1
single patch and was born out of pure desperation getting a hell lot of crap
patches from too many internal developers.

As I shared around this original code over the years, I got feedback from
various folks on varied angles:
- Dan Murphy: why cant it report required applications for it to run?
- Tero Kristo: rewrote the entire script and got me thinking along the lines of a
'patch set that needs to be applied'
- And, others who suggested tiny little things..

It was obvious, this original script needed a respin and update to newer kernel
world. So, here is another attempt with enough error handling that I could
reasonably think of in the few hours I spend rewriting.. And I do not think it
is good enough yet.. there are few things I dropped - storing dtbs+zImage per
patch to to allow for seperate verification by boot per patch and similar tiny
little thingies.. Maybe later.. I guess..

CONTRIBUTIONS:
=============
Just lets keep this on github and send pull requests to merge things up? As a
script developer, we all know that various developers have widely varying tastes.
if you feel an bug fixed or other improvements to share, send me a pull request
and we can collaborate together.

For folks wanting to write python or perl alternatives, please, go ahead and
create your own tool, just dont ask me to even touch python ;) - this remains in
bash.

INSTALL NOTES:
==============
Almost nothing - I hope you are already using bash and building kernel -
The script should crib and provide recommendations for missing packages (or is
supposed to ;) )..

For -C 'complete tests', the following are needed:
- smatch: (sudo apt-get install sqlite3 libsqlite3-dev llvm)

	http://linuxplumbersconf.com/2011/ocw//system/presentations/165/original/transcript.txt

	http://smatch.sf.net

- spatch: is provided by the coccinelle package in ubuntu

Usage:
=====
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
* Cannot have a diff pending OR be on a dangling branch base_branch should exist as well
* The default tests are selected with view of as minimal time as possible, while the '-C' tests
are the comprehensive tests which are strongly recommended before showing your patches to any other
human being.

Example usages:
===============

* Verify last commmitted patch

```
	 ./kernel_patch_verify -1
```
* Verify on top of current branch patches from location ~/tmp/test-patches

```
	 ./kernel_patch_verify -p ~/tmp/test-patches
```
* Verify *from* branch 'base_branch' till current branch

```
	 ./kernel_patch_verify -b base_branch
```
* Verify from current branch, all patches *until* 'test_branch'

```
	 ./kernel_patch_verify -t test_branch
```
* Verify, all patches from 'base_branch' until 'test_branch'

```
	 ./kernel_patch_verify -b base_branch -t test_branch
```
* Verify with complete tests, all patches from 'base_branch' until 'test_branch'

```
	 ./kernel_patch_verify -b base_branch -t test_branch -C
```

* Verify last committed patch on a native x86 build using make, gcc and bzImage

```
	 ./kernel_patch_verify -B bzImage -1
```

* Verify last committed patch on a cross_compiled ARM build using defaults

```
	 ./kernel_patch_verify -d -1
```

Some script design stuff:
========================
Alright, the shell script should be readable in it's own I hope.. anyways,
tests are organized as:
* ptest_xyz -> these tests take the patch as the argument
* ftest_xyz -> these tests take c file (impacted by the patch) as the argument
* btest_xyz -> there are of two types: the ones that take .o files as arguments
and those that build the entire kernel

Tests are organized per patch OR overall (basically run before the patch series
and after the patch series). Reports are generated after all the tests are run,
I have not tried to standardize the reports in any way, except that if there is
a 'change' in log, for example:
* build warning was created with a patch.
* build warning was removed with a patch in the series.

This will appear as a a diff (both build warning was removed or added is
considered similar) and that diff is provided in the report log. the final report
log is a consolidation of every single patch, over all results and also provides
information about the tools and versions used.

'-C' tests are reserved for ones that take time. I would like to encourage
developers to constantly use the test script to keep their code clean,
so without the '-C', it tries to run tests that take a short amount of time.
For patches that take significant time, I'd list them under '-C'. I recommend
reading the code to see the list of tests executed - This will also be printed
as you execute the tests. just remember that false positives are irritable to
developers, so be careful of the results.

The generic strategy for the test is that everything in stderr is logged, a test
should never throw anything on stdout as it just craps up the developer's screen.
If a test provides result on stdout, redirect it to stderr. Pass/fail criteria is
as follows:
* for ftest_, btest_, the before and after logs should show 0 diff. if there are
  it assumes new fail introduction
* for ptest, no output is a pass, any output tends to be a fail.


Author and versioning highlights (chronological):
--------------------------------
* Nishanth Menon Dec 2013, Dallas, TX, while lying in bed with a slight migraine
staring at a cloudy sky and spewing nonsense into vim.. and guessing that no one
might even care about this..
