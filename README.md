# wallowa

Last update: 30-June-2017

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

The rest of this README briefly describes each of the com-line utility programs and library (lib/) support modules.

Note: References to "VMS" herein are synonymous with "OpenVMS" (old-timers say that the "Open" is silent, thus: "VMS"), the venerable and powerful operating system created in the 1970s by Digital Equipment Corporation on the VAX architecture, later ported to Alpha and now to IA-64 (HP Integrity) architectures, currently marketed by Hewlett Packard Enterprise Co., with current engineering, development and maintenance support by VMS Software Inc. (VSI). "DCL" is the Digital Command Language command-line interpreter (shell) on VMS.

## New Ideas and Stubs

These are early ideas, may be subject to change, better ideas/names and/or dropping as no-good-after-further-consideration:

**quepp.rb** -- A VMS batch or printer queue listing pretty-printer.  The `SHOW QUEUE` command produces truly aweful output (I've coped with it for years), and it occurs that this ugly output could be harvested and reformatted in a much more useful way.  We'll see...

**ls.rb** -- Well, why not.  I wrote a VMS DCL-emulator for Linux, including a VMS-style `dir` (DIRECTORY) command; why not take a shot at producing Linux/Unix `ls`-style output for *nix-path/filenames on VMS?

## Com-Line Utility Programs and the OptionParser Gem

The majority of the utility programs in this section use the OptionParser (optparse) gem to provide a consistent com-line parse look-&-feel for the user (me). Early on, it occurred to me (as it has to so many other coders) that there's a common subset of com-line options that can and should be present in *any* family of utilities, and I've provided for these options in nearly all such programs:

  * *--about* (or *-a*)           -- display program identification information (see lib/AboutProgram.rb)
  * *--verbose* (or *-v*)         -- provide non-silent &/or progress output
  * *--dryrun* (or *-n*)          -- test (rehearsal) mode, show but *do not* actually __do__
  * *--help* (or *-h* or *-?*)   -- display help text
  * *--debug=N* (or *-dN*)       -- show debug information/output (levels N = 1, 2 or 3)

All such programs provide a *--help* (*-h*) option which displays specific help text: purpose and options.

Only a few programs in this category do not use OptionParser, and these only require very simple or no command line input; perhaps only an argument value, or nothing at all.

A different subset of these programs are launched using a rather tricky (at least to derive, not to use now that it's been developed) functional mechanism (`ResetGlobbing`) which actually temporarily **defeats** the shell's globbing behavior for that one command (and without the user's noticing or bothering with it).  This is done so that the program/script itself will actually receive the glob-wildcard characters as part of the command line argument values -- the shell does not expand/glob these wildcards, allowing the program to do more advanced things with them, including wildcard expansion on its own terms.  Programs in this category include the ones which implement the OpenVMS DCL Emulator commands:

    * dcl.rb
    * dir.rb
    * dclrename

See in particular the description for the script **dcl.rb** below for more information.

**addtimes.rb** -- Adds or subtracts time intervals (or durations) as provided on the command line or via prompting.  Ever had a finicky time-reporting program (or boss) where you've needed to pre-check task times/durations before you commit them to data entry?  This utility accepts data in hours-minutes-seconds [hh:]mm[:ss] format, and sums those durations.  If subtracting, it prompts for an initial duration from which to subtract data durations.

**adoptdirtree.rb** and **adopt.sh** --

**audiocat.rb** -- Pop music is completely "song" oriented -- But the word *song* means something very specific, and is an inappropriate term for music (whether "classical", "art" or other) in general. The "music industry" is completely "track" oriented, where `track = song` -- This is completely and totally wrong for serious music.

This utility addresses a common problem when ripping music CDs to digital files (I load my collection to my cellphone to play on my long daily commute): It joins (concatenates) multiple separately ripped "tracks" into a single digital file, so that rather than playing random(ized) tracks, I can play a complete piano sonata, concerto or symphony, as the composer intended it to be heard. It handles `.ogg` and `.mp3` audio files. Believe me, Bach's *Goldberg Variations* are meant to be enjoyed as a coherent whole, not in bloody pieces.

**autoinstall.rb** -- Upgrading a Linux distro (such as Ubuntu), especially a bare-metal reinstall, presents a real challenge to getting the newly installed instance completely back in shape with regard to all the various add-on products and packages that you'd installed on your previous Linux instance. Most of the time, you forget most everything that you'd installed -- getting everything (at least all that's important) back on-board is a real problem.

This script is a sophisticated driver for the `apt-get install` command, and uses a simply-structured text file, a `PackageInstallation*.list`, to reinstall everything that's important after a bare-metal Linux rebuild. All that's needed is the discipline to keep a package-installation text file up-to-date with your ongoing configuration.

**bru.rb** -- An intelligent "wrapper" for the powerful **rsync** program (which has way too many options and switches for every conceivable purpose, including ones that you'd never see or use).  This utility provides a simplified command-line options and arguments structure, optional configuration files to "remember" specific backup tasks, simplified/filtered output from the *rsync* subprocess, and more.

**datecalc.rb** -- A date calculator (I'd previously written a similar utility on VMS in Pascal) which can determine a date which is a number of days after or before a given date, the number of days between two dates, and the number of days from "today" until a later date (as a special case of "between").

**dcl.rb** -- Currently, I spend ~50% of my command-line time on DCL/VMS (see description of **dir.rb** below) and ~50% on bash/Linux. Sometimes my fingers don't know whether to type `dir` or `ls`, `copy` or `cp`... Wouldn't it be great if some DCL-style commands were actually available in bash?  Not just command aliases, but entire command syntax and behavior. This script is a DCL emulator -- at least a partial one -- which brings several file commands in DCL-style to bash:

  * `copy` for `cp`
  * `create` for `touch`
  * `delete` for `rm`
  * `rename` for `mv`
  * `dir` for `ls`
  * `search` for `grep`
  * (preliminary ideas for `purge` and `show` have not been implemented, and may be jettisoned as practically inappropriate)

In addition, a selection of DCL lexical functions `f$edit`, `f$element`, `f$extract`, `f$fao`, `f$length`, ... are provided -- this script is sort of a Swiss Army knife of DCL functions and operations transplanted into bash. Individual commands and functions are invoked by command aliases (constructed by a maintenance function in this script), and all command aliases use the bash globbing defeat function `ResetGlobbing`. See also **lib/DCLcommands.rb** and **lib/DCLfunctions** which actually implement the emulated commands and functions.

**dclrename.rb** -- An alternate or partner implementation of top-level processing for the DCL `rename` emulated command -- it provides for a test harness and exploratory platform for this process, with an eye to future wildcard processing enhancements. It's also the first place to implement and test additional renaming schemes, like UPPER- and lower-casing, CamelCasing, snake_casing, "convert all spaces to underscores" and its inverse, and compression of multi-runs of ' ' and '_' characters.

**dir.rb** -- My career has long been associated with the VMS operating system, and my fingers and eyes have spent thousands of hours on the DCL command line. I guess I've viewed tens-of-thousands of directory listings, so I've developed habits and preferences based on that long use and exposure.  When I came to embrace Linux and its shells for my desktop and laptop systems, I found the output of the `ls -la` command particularly frustrating -- the essential information's all there, but it's entirely in the wrong order!  Well, why can't I do Linux directory listings in (near) VMS/DCL format?  This script does just that.  `dir` also uses the `ResetGlobbing` function to turn off shell (bash) globbing, allowing the script to receive arguments like `*.rb` unexpanded in ARGV, and to handle wildcard globbing internally.

**eva.rb** -- A utility and demo script which exercises the full capabilities of `lib/ppstrnum`'s `thousands`, `numbernames`, `pp_numstack`, `asc_numstack` and `desc_numstack` methods. Accepts one or more command-line arguments (`""`-quoted) as an mathematical expressions to `eval`.

This script has evolved:  1. It was originally conceived as a means to evaluate numeric (arithmetic) expressions involving `Bignum` numbers (a deprecated class with v2.4+, all's Integer and Numeric now; in this original form, it was called bignum.rb).  Then, 2. Recognized how to make this work for Math trigonometric and transcendental methods too, which added a heap of functionality.  Then, 3. Ephiphany: The core `eval` method works generically for `String` methods, and possibly other things.  But, 4. Discovered that Tcl has already commandeered the command word "eval", so settled on `eva` instead.

**ezekiel.rb** -- This program is a *toy* which plays with the (bogus) numerology/gematria espoused by the 2007 novel "The Ezekiel Code" by Gary Val Tenuta (Outskirts Press).  Tenuta's numerology (algorithm, referred to as "cross-adding") is spelled out in Chapter ~2~ of the novel.  The plot of this story hinges upon the "great significances" of various phrases and words as cross-added by this numerology -- See the companion text file `Ezekiel Numerology Test Phrases.cross_sums` for a (nearly) complete list of cross-added phrases/words (and noting a few errors in the novel-author's own sums).  The author of this program in no way endorses, or even believes in, the numerological and/or religious notions and ideas put forth ion that novel; however, it is amusing to play with (and cross-check) the various sums and cross-sums from that work of fiction -- if only to demonstrate that one can "make great significance" out of damn near any/every cross-sum you can compute!

**factorial.rb** and **fibonacci.rb** -- You never know when you'll need 512!, or the 1,076th Fibonacci number.  Thanks to Ruby Bignums, you can now calculate these large or giant numbers: `$ factorial 512` or `$ fibonacci 1076`.  You can also calculate a series for either:  `$ factorial 10..20` or `$ fibonacci 1..32`.  Both scripts include both "classical" recursive and "memoized" recursive versions of the respective factorial or Fibonacci series calculations, and **factorial.rb** includes two extra methods for `permutation` (ordered arrangements of `n` things taken `k` at a time) and `combination` (unordered selections of `n` things taken `k` at a time) calculations.  See also **fibonacci_bb.rb** below for a benchmarked version.

**filecomp.rb** -- An upscale wrapper for the basic two-file `diff` utility, performs a fast check for file equality or non-equality using an intelligent combination of fast comparisons based on message digests (SHA-1 (default) or SHA-[256,384,512]), files times (mtime, atime, ctime), file sizes (byte-counts), and/or file-type "magic numbers" (internal first-bytes signature). Files that are "the same" are simply reported as "file1 == file2"; files that are "different" are reported as "file1 <> file2" and, for these, offers to invoke one of several GUI or character-based "file differences" utilities (`meld` is the GUI default tool). These tools are available based on which file-diff tools are actually installed on your system -- the `--help` option displays those diff-tools that are available. Can compare an explicitly named pair of files, or a file-group compared with that same group in another directory.

**fileenhance.rb** -- A test/demo driver for the `File.parse` class method in **lib/FileEnhancements.rb**, also uses `quts` and `pquts` methods in **lib/pquts.rb**.

**fixcopyright.rb** -- Updates copyright notice lines, like "Copyright (c) year-year" and/or "Copyright © year" to a year-range ending with either the current year or a specific year as given by the `--copyrightyear=YEAR` option. Either modifies the source file directly (default), or for the faint-of-heart, makes a `*.*.backup` copy if `--backup` is specified.

**fspec.rb** -- A new (VMS-only) demo script which uses newly-SWIGged `DECC::from_vms` and `DECC::to_vms` DEC/VMS CRTL (C Runtime Library) routines to translate between VMS-style file specifications like `sys$sysdevice:[lricker.com]boottime.com` and *nix-style file paths like `/sys$sysdevice/lricker/com/boottime.com`.  Useful for demo-&-learning, and for diagnosing some difficult-to-predict corner-cases.

**how-big-is-smallest-bignum.rb** -- Determines (or discovers) the "boundary" between the largest Integer value and the smallest Bignum value on a given system/architecture, using a binary-search-like algorithm to detect the point at which the next Integer value becomes an actual Bignum value.  This demonstration becomes irrelevant with Ruby versions from Ruby v2.4 and later, as classes FixNum and BigNum become obsolete, internalized and merged into class Integer.

**how-big-is-smallest-bignum2.rb** -- An alternative approach to the same problem (above), this one contributed by Andrew Grimm on http://stackoverflow.com/questions/535721/ruby-max-integer (6-Jan-2012).  This demonstration also becomes irrelevant with Ruby versions from Ruby v2.4 and later, as classes FixNum and BigNum become obsolete, internalized and merged into class Integer.

**how-many-chords-on-piano.rb** -- This script finally answers the age-old question: "How many distinct chords can be played on the piano?", and it contains more internal comments than code, so see the source code for more information.  Also, this particular question/issue is discussed more thoroughly here: http://therockjack.com/2014/02/17/how-long-until-we-run-out-of-notes/, which in turn leads to this: https://www.quora.com/How-long-will-it-be-until-we-run-out-of-combinations-of-notes-for-a-classical-music-composition/answer/Lorin-Ricker ...enjoy.

**lsfunction.rb** -- Anyone else as frustrated as I am that **bash** (and other shells?) doesn't provide a command to *selectively* list an in-memory shell function by name?  Sure, the **set** command will dump the whole enchilada, in one huge stream of lines, but you're left to scroll-back and try to find the one function you need to review.  This utility allows you to list a shell function, or environment variable, by name, and even supports a simple wild-card character (currently '%') to list (for example) just the functions whose name starts with 'f' (as in `$ lsfunction -f f%`).

**mdrender.rb** -- A *github/markdown* rendering utility (early version).

**microscope.rb** -- Based on ideas from Pat Shaughnessy's excellent book ["Ruby Under A Microscope"](http://patshaughnessy.net/ruby-under-a-microscope) (ISBN 978-1-59327-527-3, [No Starch Press](http://www.nostarch.com/rum), 2014), and on the **Ripper** Ruby Gem, applies lexical (token) analysis, parser (sexp/AST) analysis, and/or compiler (YARV) analysis to a Ruby source file, or to a limited range of lines in a Ruby source file.

**mkssfpath.rb** and **mkssf.sh** --

**msgd.rb** -- This script was inspired by a desire to bring modern message digests, including SHA256, SHA384, SHA512, RIPEMD-160, as well as MD5 and SHA1 (both deprecated as insecure), to VMS (OpenVMS), currently limited (as of 1970s thru 2017 at least) to a `CHECKSUM` command which provides only XOR, CRC and MD5 digest algorithms.  `msgd` blends functionality from both Linux (Unix) `sha(256,384,512)sum` (and `md5sum`) commands with VMS's `CHECKSUM`, reproducing the *nix output format standard for each of the supported message digests, and the ability to redirect that output to a text file for subsequent use in checking/comparing other instances of the same file (e.g., ones that have been FTP-transferred from one system to another).  On VMS, it can optionally create a DCL local symbol (variable) which contains the digest string (similar to `CHECKSUM`'s `CHECKSUM$CHECKSUM` symbol).  Includes extensive man-page-like help (see `--instructions` or `--man`).

**myexternalip.rb** -- A tiny (could be a 1-liner) script to retrieve this system's external IP-address from http://myexternalip.com.

**pgmheaderfixup.rb** --

**process.rb** -- *nix geeks and sys-admins know how to kill an errant process, supposing that s/he can identify it, usually with pipe-tricks like `ps aux | grep bad_proc_name`. Sometimes you may see this as `ps aux | grep [b]ad_proc_name` just so the grep-process itself doesn't show in the output. This script handles both "show process" and "kill that process" -- its `--kill` option makes that difference, so this one's kind'a bi-modal.  Use directly as `process [options] proc_name`, it's a `SHOW SYSTEM` VMS-equivalent.

My bash profile script sets two aliases, `killmy` to do `process --kill` (and `killsys` for `sudo /home/user/bin/process --kill`) for personal or system/world processes. Because of obvious parallels between Linux and VMS, this script is designed to work for both operating systems, although it has not (yet) been tested and deployed on VMS (as of Jan'16, I have received a beta release of Ruby v2.2 for OpenVMS, and am participating in check-out testing for this port). This script was also the subject of a Ruby introductory presentation at OpenVMS Bootcamp 2014, Boston. Addendum 16-June-2017: This script now works correctly on both Linux and VMS, where it provides parallel functionality.

**purgekernel.rb** -- (work-in-progress)

**regex.rb** -- Inspired by a technique (suggestion) in the regex chapter of *the Pickaxe Book* (**Programming Ruby 2.0 & 1.9**, Dave Thomas, et al), this program provides a way to experiment with regexes and target strings, displaying the relevant contents of a pattern match's MatchData object. Provides value as an immediate com-line utility, but does not compare in comprehensive functionality to online/web tools like [regex101.com](http://www.regex101.com) or [debuggex.com](http://www.debuggex.com), or to JGS's [RegexBuddy](http://www.regexbuddy.com).

**rel2bin.rb** -- I keep my program developments (e.g., Ruby scripts) separate from my production commands in **~/bin/**; this script is my "release to **bin/**" tool which: a) checks that the source file in the dev-directory is newer (later) that the script in **~/bin/** -- if it is: b) copies a script from my dev-directory to **bin**/; c) strips off any clumsy file extension, like **.rb**, so that the script name can be used as a simple command verb, like `bru`, `datecalc` or `termchar`; d) embellishes the copied script file with consistent file ownership and an executable **x** protection mask; e) handles **lib/** library script files, copying these to **bin/lib/** so that require\_relative can find them (Ruby scripts, for this special case, the file extension is _retained_).  The current version is Ruby- and shell-centric, but could readily be enhanced for Python and other script languages.

**ruler.rb** -- Imposes (displays) a character-metric horizontal ruler onto the current terminal, at any cursor-addressable line position of the display, over-writing any text at that position. Color, hash-mark style and position is controllable with command-line options, with reasonable defaults (blue ruler at top of screen/display with hash marks below the ruler).

**stringenhance.rb** -- A somewhat old-fashioned test driver for **lib/StringEnhancements.rb** methods.

**stripcomments.rb** -- This script strips (removes) comment lines from a source-code file, where comment lines are started by hash-marks '#' (for Ruby, Python, Perl, bash, etc.); it removes both stand-alone (single-line) comments and those embedded in source lines. The script uses STDIN and STDOUT, filenames on com-line, including redirection, so this program can be used as a filter in a pipeline.

**teamscram.rb** -- This script started out as a test-driver for **lib/Scramble.rb**, but turned into a pretty neat utility of its own. It creates groupings or "teams" of individuals from a data-file with team-members' names (or cards-by-name-suit, fruits, or anything else you can name) on one-per-line -- it then creates arbitrary groups by first shuffling (randomizing) the name set (pool of people, deck of cards, etc.) and then "dealing" them into subsets (teams, hands, etc.). Useful in a classroom situation where you'd like to create *ad-hoc* programmer teams from the class roster, and keep team memberships well-mixed.

**termchar.rb** -- A very simple form of **show terminal** (like VMS) to show the terminal window's geometry (width-by-length, characters-by-lines). Uses **lib/TermChar.rb**. Uses one of two methods -- either `IO.console.winsize` (for Ruby v2.0+) or output of  `%x{stty size}` -- to determine terminal geometry depending on Ruby version running this script.

**tonerow.rb** -- This algorithm/program has been with me since college (a long, long time ago!), where I first implemented it in Fortran and PL/1 (languages taught back then); later I reimplemented it in (at least) Pascal (two compiler/dialects), and a couple of other languages since forgotten -- now resurrected in Ruby.  This script generates a "magic square", given a dodecaphonic (12-tone) row: The square is a 12-by-12 matrix of tones (integers 0 thru 9, with D and E standing for tone (pitch class) values 10 and eleven) -- the matrix represents all conventional combinations and permutations of that 12-tone row, at all 12 transposed pitches, including original and transpositions (rows read left to right), retrogrades (rows right to left), inversions (columns read top to bottom) and retrograde-inversions (columns bottom to top).

A 12-tone row input might look like "45130289D67E" (the row used in Webern's Piano Variations, Op. 27), where "0" is by convention pitch class (or tone) C.  Note that the top-left to bottom-right diagonal of the resulting matrix always has the same pitch class value, for the Webern row/example, the tone 4 representing E.

**what.rb** -- Attribution:  This "code fragment" comes directly and unaltered  (well, almost) by cut-&-paste (well, almost) from Avdi Grimm's [RubyTapas education series](https://rubytapas.com) (https://rubytapas.com), Episode 471 entitled ['Which'](https://www.rubytapas.com/2017/03/20/episode-471-which/) (https://www.rubytapas.com/2017/03/20/episode-471-which/). This code snippet is just too good, deserves to be used in a real-live tool! You, dear reader, are strongly encouraged to read Avdi's lucid code design walkthru in the RubyTapas episode above...

**wordfrequencies.rb** -- Tallies up the frequencies of words in a document, dropping "little/noise" words (like a, the, but, to, too, etc.), and sorting the resulting list and displaying the "top-N" as requested by the user.

**xchart.rb** -- This script displays help-information about the Ruby **Exception** class hierarchy, together with rescue examples and with color embellishments.

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

## Library (**lib/**) Support Modules

**lib/AboutProgram.rb** -- Provides method `about_program`, which can be called by an OptionParser *--about* or *-a* option, e.g.:  
    # --- About option ---
    opts.on_tail( "-a", "--about", "Display program info" ) do |val|
      require_relative 'lib/AboutProgram'
      options[:about] = about_program( PROGID, AUTHOR, true )
    end  # -a --about
A command-line use might produce something like:  

    $ bru -a
    bru v2.7 (09/07/2015) ...on Ruby v2.4.0
    Lorin Ricker, Elbert, Colorado, USA
Note that the method `about_program` includes the version-number of the Ruby interpreter which runs the script.

**lib/ANSIseq.rb** (and **ANSISEQ.COM** and **CLS.COM**) --

**lib/AppCmdCompletions.rb** --

**lib/appconfig.rb** --

**lib/ArrayEnhancements.rb** --

**lib/AskPrompted.rb**, **lib/GetPrompted.rb** and **lib/Prompted.rb** --

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

**lib/ppstrnum.rb** --

**lib/pquts.rb** --

**lib/Scramble.rb** --

**lib/ScriptLines.rb** --

**lib/StringCoerce.rb** --

**lib/StringEnhancements.rb** --

**lib/StringUpdater.rb** --

**lib/SumOfDigits.rb** --

**lib/TermChar.rb** --

**lib/Thousands.rb** --

**lib/TimeEnhancements.rb** --

**lib/WhichOS.rb** --
