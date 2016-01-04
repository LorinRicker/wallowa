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

  * **.git/** -- The git/GitHub repo itself

The rest of this README briefly describes each of the com-line utility programs and library (lib/) support modules.

## Command-Line Utility Programs

**adoptdirtree.rb** and **adopt.sh** --

**audiocat.rb** --

**audioscram.rb** --

**autoinstall.rb** --

**bru.rb** -- An intelligent "wrapper" for the powerful *rsync* program (which has way too many options and switches for every conceivable purpose, including ones that you'd never see or use).  This utility provides a simplified command-line options and arguments structure, optional configuration files to "remember" specific backup tasks, simplified/filtered output from the *rsync* subprocess, and more.

**capture_all_matches.rb** --

**composers.rb** --

**datecalc.rb** --

**dcl.rb** --

**dclrename.rb** --

**deltree.rb** --

**dir.rb** --

**enigma_v1.rb** --

**factorial.rb** --

**fibonacci.rb** --

**filecomp.rb** --

**fileenhance.rb** --

**fixcopyright.rb** --

**googlesearch.rb** --

**how-big-is-smallest-bignum.rb** --

**how-big-is-smallest-bignum2.rb** --

**how-many-chords-on-piano.rb** --

**lsfunction.rb** --

**microscope.rb** --

**mkssfpath.rb** and **mkssf.sh** --

**pgmheaderfixup.rb** --

**process.rb** --

**purgekernel.rb** --

**randomwordgenerator.rb** --

**regex.rb** --

**rel2bin.rb** --

**ruler.rb** --

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

**argvdemo.rb** --

**Demos/Chained_Iterators.rb** --

**Demos/DeleteCharFromMiddleOfString.rb** --

**Demos/EnvironmentVariables.rb** --

**Demos/factr.rb** --

**Demos/HappyBirthday.rb** --

**Demos/HelloWorld.rb** and **Demos/helloworld_ml.rb** --

**Demos/LoadPath.rb** and **Demos/LoadPath2.rb** --

**Demos/Print_All_Classes.rb**, **Demos/Print_All_Exceptions.rb** and **Demos/Print_All_Modules.rb** --

**Demos/programfilenames1.rb** and **Demos/ProgramFileNames2.rb** --

**Demos/QuotedOutput.rb** --

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
