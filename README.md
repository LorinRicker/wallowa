# wallowa

## Overview

This repository is unconventional in that it serves as a collection-point for a rather large number of Ruby com-line utilities and educational programs, primarily designed and developed for a Ruby Immersion Bootcamp (multi-week class), but also for individual use and sharing within the Ruby Community.

Any of the individual com-line programs could be segregated out into a Ruby Gem, as could each/any of the library (lib/) components -- however, this is currently "left as an exercise" to a future me or other individuals.

The name of this repo, "wallowa", is a Nez Perce Indian word meaning "fish trap," and is the name of the region/county in northeastern Oregon where I grew up -- thus, it has a personal meaning to me, but serves only as an arbitrary name for others.

This repo consists of ~50 (and counting) utility and demo programs --

  * The utility programs are essentially all of the same general "command line utility" form, with the OptionParser (optparse) gem pulling the weight of parsing command line components, and each has its own focus and/or function.

  * The demo programs are mostly ad-hoc from the com-line interface perspective, and each serves to demonstrate a particular Ruby principle, idea, concept and/or approach to some problem.

There are nine subdirectories (folders) in the repo:

  * **Archives/** -- a holding pen for some old(er) ideas and versions that I'm not quite willing to bag (delete) yet, useful only as historical comparison (if that).

  * **composers_rename/** -- a working directory for a one-time-use script, comprename.rb and a driver-data file composers_rename.lis

  * **Demos/** -- a small collection of Ruby demonstrations

  * **Docs/** -- a few odds-&-ends documentation files that are related to other things in this repo; most significant is a text file, "Ruby Haiku.txt", which still gets an occasional new idea and haiku, just for fun

  * **gpl/** -- the GNU GENERAL PUBLIC LICENSE which applies to this repository

  * **lib/** -- the primary subdirectory, the library full of support modules (proto-gems) used throughout the com-line utility programs (especially)

  * **MusicDocs/** -- a group of 12-tone row documents, created by the tonerow.rb utility program, for key and classic works in the genre by Schoenberg and Webern

  * **templates/** -- a small collection of Ruby program templates, just for getting a new program started in a consistent way

  * **.git/** -- The *wallowa* git/GitHub repo itself

The rest of this README briefly describes each of the com-line utility programs and library (lib/) support modules.

## Com-Line Utility Programs and the OptionParser Gem

The majority of the utility programs in this section use the OptionParser (optparse) gem to provide a consistent com-line parse look-&-feel for the user (me). Early on, it occurred to me (as it has to so many other coders) that there's a common subset of com-line options that can and should be present in *any* family of utilities, and I've provided for these options in nearly all such programs:

  * **-a** or **--about**          -- display program identification information
  * **-v** or **--verbose**        -- provide non-silent &/or progress output
  * **-n** or **--dryrun**         -- test (rehearsal) mode, show but *do not* __do__
  * **-h** or **-?** or **--help** -- display help text
  * **-dN** or **--debug=N**       -- show debug information/output (levels N = 1, 2 or 3)

Only a few programs in this category do not use OptionParser, and these only require very simple or no command line input; perhaps only an argument value, or nothing at all.

A different subset of these programs are launched using a rather tricky (at least to derive, not to use now that it's been developed) functional mechanism (`ResetGlobbing`) which actually temporarily **defeats** the shell's globbing behavior for that one command (and without the user's noticing or bothering with it).  This is done so that the program/script itself will actually receive the glob-wildcard characters as part of the command line argument values -- the shell does not expand/glob these wildcards, allowing the program to do more advanced things with them, including wildcard expansion on its own terms.  Programs in this category include the ones which implement the OpenVMS DCL Emulator commands:

    * dcl.rb
    * dir.rb
    * dclrename

See in particular the description for the script **dcl.rb** below for more information.

**adoptdirtree.rb** and **adopt.sh** --

**audiocat.rb** --

**audioscram.rb** --

**autoinstall.rb** --

**bru.rb** -- An intelligent "wrapper" for the powerful **rsync** program (which has way too many options and switches for every conceivable purpose, including ones that you'd never see or use).  This utility provides a simplified command-line options and arguments structure, optional configuration files to "remember" specific backup tasks, simplified/filtered output from the *rsync* subprocess, and more.

**datecalc.rb** --

**dcl.rb** -- Currently, I spend ~50% of my command-line time on DCL/VMS (see description of **dir.rb** below) and ~50% on bash/Linux. Sometimes my fingers don't know whether to type `dir` or `ls`, `copy` or `cp`... Wouldn't it be great if some DCL-style commands were actually available in bash?  Not just command aliases, but entire command syntax and behavior. This script is a DCL emulator -- at least a partial one -- which brings several file commands in DCL-style to bash:

  * `copy` for `cp`
  * `create` for `touch`
  * `delete` for `rm`
  * `rename` for `mv`
  * `dir` for `ls`
  * `search` for `grep`
  * (preliminary ideas for `purge` and `show` have not been implemented, and may be jettisoned as practically inappropriate)

In addition, a selection of DCL lexical functions `f$edit, f$element, f$extract, f$fao, f$length ...` are provided -- this script is sort of a Swiss Army knife of DCL functions and operations transplanted into bash. Individual commands and functions are invoked by command aliases (constructed by a maintenance function in this script), and all command aliases use the bash globbing defeat function `ResetGlobbing`. See also **lib/DCLcommands.rb** and **lib/DCLfunctions** which actually implement the emulated commands and functions.

**dclrename.rb** -- An alternate or partner implementation of top-level processing for the DCL `rename` emulated command -- it provides for a test harness and exploratory platform for this process, with an eye to future wildcard processing enhancments.

**deltree.rb** -- (not-yet-implemented)

**dir.rb** -- My career has long been associated with the OpenVMS (old-timers say that the "Open" is silence, thus: "VMS") operating system, and my fingers and eyes have spent thousands of hours on the DCL command line. I guess I've viewed tens-of-thousands of directory listings, so I've developed habits and preferences based on that long use and exposure.  When I came to embrace Linux and its shells for my desktop and laptop systems, I found the output of the `ls -la` command particularly frustrating -- the essential information's all there, but it's entirely in the wrong order!  Well, why can't I do Linux directory listings in (near) VMS/DCL format?  This script does just that.  `dir` also uses the `ResetGlobbing` function to turn off shell (bash) globbing, allowing the script to receive arguments like `*.rb` unexpanded in ARGV, and to handle wildcard globbing internally.

**factorial.rb** and **fibonacci.rb** -- You never know when you'll need 512!, or the 1,076th Fibonacci number.  Thanks to Ruby Bignums, you can now calculate these large or giant numbers: `$ factorial 512` or `$ fibonacci 1076`.  You can also calculate a series for either:  `$ factorial 10..20` or `$ fibonacci 1..32`.  Both scripts include both "classical" recursive and "memoized" recursive versions of the respective factorial or Fibonacci series calculations, and **factorial.rb** includes two extra methods for `permutation` (ordered arrangements of `n` things taken `k` at a time) and `combination` (unordered selections of `n` things taken `k` at a time) calculations.  See also **fibonacci_bb.rb** below for a benchmarked version.

**filecomp.rb** --

**fileenhance.rb** -- A test/demo driver for the `File.parse` class method in **lib/FileEnhancements.rb**, also uses `quts` and `pquts` methods in **lib/pquts.rb**.

**fixcopyright.rb** --

**how-big-is-smallest-bignum.rb** -- Determines (or discovers) the "boundary" between the largest Integer value and the smallest Bignum value on a given system/architecture, using a binary-search-like algorithm to detect the point at which the next Integer value becomes an actual Bignum value.

**how-big-is-smallest-bignum2.rb** -- An alternative approach to the same problem (above), this one contributed by Andrew Grimm on http://stackoverflow.com/questions/535721/ruby-max-integer (6-Jan-2012).

**how-many-chords-on-piano.rb** -- This script finally answers the age-old question: "How many distinct chords can be played on the piano?", and it contains more internal comments than code, so see the source code for more information.  Also, this particular question/issue is discussed more thoroughly here: http://therockjack.com/2014/02/17/how-long-until-we-run-out-of-notes/, which in turn leads to this: https://www.quora.com/How-long-will-it-be-until-we-run-out-of-combinations-of-notes-for-a-classical-music-composition/answer/Lorin-Ricker ...enjoy.

**lsfunction.rb** -- Anyone else as frustrated as I am that **bash** (and other shells?) doesn't provide a command to *selectively* list an in-memory shell function by name?  Sure, the **set** command will dump the whole enchilada, in one huge stream of lines, but you're left to scroll-back and try to find the one function you need to review.  This utility allows you to list a shell function, or environment variable, by name, and even supports a simple wild-card character (currently '%') to list (for example) just the functions whose name starts with 'f' (as in `$ lsfunction -f f%`).

**mdrender.rb** -- A *github/markdown* rendering utility (early version).

**microscope.rb** --

**mkssfpath.rb** and **mkssf.sh** --

**pgmheaderfixup.rb** --

**process.rb** --

**purgekernel.rb** --

**regex.rb** -- Inspired by a technique (suggestion) in the regex chapter of *the Pickaxe Book* (**Programming Ruby 2.0 & 1.9**, Dave Thomas, et al), this program provides a way to experiment with regexes and target strings, displaying the relevant contents of a pattern match's MatchData object. Provides value as an immediate com-line utility, but does not compare in comprehensive functionality to online/web tools like [regex101.com](http://www.regex101.com) or [debuggex.com](http://www.debuggex.com), or to JGS's [RegexBuddy](http://www.regexbuddy.com).

**rel2bin.rb** --

**ruler.rb** -- Imposes (displays) a character-metric horizontal ruler onto the current terminal, at any cursor-addressable line position of the display, over-writing any text at that position. Color, hash-mark style and position is controllable with command-line options, with reasonable defaults (blue ruler at top of screen/display with hash marks below the ruler).

**stringenhance.rb** --

**stripcomments.rb** --

**teamscram.rb** --

**termchar.rb** --

**tonerow.rb** --

**wordfrequencies.rb** --

**xchart.rb** --

## Benchmark Programs

**fibonacci_bb.rb** --

**fixbig_mult_bb.rb** --

**incr_max_array_element_bb.rb** --

**strcat_bb.rb** --

## Demo Programs

**Demos/argvdemo.rb** --

**Demos/capture_all_matches.rb** --

**Demos/Chained_Iterators.rb** --

**Demos/DeleteCharFromMiddleOfString.rb** --

**Demos/enigma_v1.rb** --

**Demos/EnvironmentVariables.rb** --

**Demos/factr.rb** --

**Demos/HappyBirthday.rb** --

**Demos/googlesearch.rb** --

**Demos/HelloWorld.rb** and **Demos/helloworld_ml.rb** --

**Demos/LoadPath.rb** and **Demos/LoadPath2.rb** --

**Demos/Print_All_Classes.rb**, **Demos/Print_All_Exceptions.rb** and **Demos/Print_All_Modules.rb** --

**Demos/programfilenames1.rb** and **Demos/ProgramFileNames2.rb** --

**Demos/QuotedOutput.rb** --

**Demos/randomwordgenerator.rb** --

**Demos/RubyConfig.rb** --

**Demos/RunningOn.rb** --

**Demos/Sheldon.rb** --

**Demos/SieveOfEratosthenes.rb** --

**Demos/Transform - All the World's a Stage.rb** --

## Library (lib/) Support Modules

**lib/ANSIseq.rb** (and **ANSISEQ.COM** and **CLS.COM**) --

**lib/AppCmdCompletions.rb** --

**lib/appconfig.rb** --

**lib/ArrayEnhancements.rb** --

**lib/AskPrompted.rb** --

**lib/binary.rb** --

**lib/Combinatorics.rb** --

**lib/DateCalc.rb** --

**lib/DCLcommand.rb** and **lib/DCLfunction.rb** --

**lib/Diagnostics.rb** --

**lib/dpkg_utils.rb** --

**lib/ErrorMsg.rb** --

**lib/FileComparison.rb** --

**lib/FineEnhancements.rb** --

**lib/FileFilters.rb** --

**lib/filemagic.rb** --

**lib/FindAllPosBeginEnd.rb** --

**lib/GetPrompted.rb** --

**lib/ppstrnum.rb** --

**lib/pquts.rb** --

**lib/Prompted.rb** --

**lib/require_relative.rb** --

**lib/Scramble.rb** --

**lib/ScriptLines.rb** --

**lib/StringCoerce.rb** --

**lib/StringEnhancements.rb** --

**lib/StringUpdater.rb** --

**lib/TermChar.rb** --

**lib/Thousands.rb** --

**lib/TimeEnhancements.rb** --

-----
Last update: 24-Jan-2016
