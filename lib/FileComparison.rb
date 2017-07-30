#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# FileComparison.rb
#
# Copyright © 2011-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 4.7, 07/30/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# -----

def app_installed?( app, debug )
  response = %x{ whereis #{app} }.chomp.split(' ')
  $stdout.puts "$ whereis #{app}: #{response}" if debug >= DBGLVL2
  return response[1]  # "/usr/bin/app", or nil if not installed
end  # app_installed?

def launch_dirdiff( dir1, dir2, options )
  dirdifftool = []
  # If DIRDIFF_TOOLS contains more than one tool, pick the last one installed...
  unless DIRDIFF_TOOLS.each { |d| dirdifftool = app_installed?( d, options[:debug] ) }
    $stderr.puts "%#{PROGNAME}-f-noapp, no 'dirdiff' application found or installed"
    exit false
  end
  cmd  = dirdifftool
  cmd += " -a -S" if dirdifftool == 'dirdiff'
  cmd += " '#{dir1}' '#{dir2}'"
  $stdout.puts "    $ #{cmd.underline.color(:blue)} &"
  spawn( cmd )
end  # launch_dirdiff

# -----

def fileComparison( fname1, fname2, options )

  [ fname1, fname2 ].each_with_index do | f, i |
    if !File.exists?(f)
      puts "%filecomp-e-fnf, file#{i+1} not found: #{f}"
      # if working on multi-file list, just return, otherwise exit with fail-status
      return false
    end  # if !File.exists?(f)
  end

  f1 = Hash.new
  f2 = Hash.new
  f1[:name] = fname1
  f2[:name] = fname2

  # Rake file comparisons looks at File.mtime (not .ctime or .atime)
  # Method msgdigest defined in lib/filemagic.rb --
  f1[:mtime]  = File.mtime(f1[:name])
  f1[:size]   = File.size(f1[:name])
  f1[:digest] = f1[:name].msgdigest( options[:digest] )
  f1[:type], f1[:magictext] = f1[:name].filemagic

  f2[:mtime]  = File.mtime(f2[:name])
  f2[:size]   = File.size(f2[:name])
  f2[:digest] = f2[:name].msgdigest( options[:digest] )
  f2[:type], f2[:magictext] = f2[:name].filemagic

  if options[:dependency]
    # Files are mtime-dependent -- Test that Src-file is _older_ than Tar-file
    # (like Rake's file-comparison trigger):
    equaltimes = f1[:mtime] <= f2[:mtime]
    # And force times evaluation if dependency:
    options[:times] = true
  else
    # Files are mtime-equal -- Test that f1's mtime equals f2's mtime:
    equaltimes = f1[:mtime] == f2[:mtime]
  end

  equalmagic = f1[:type] == f2[:type]
  equalsizes = f1[:size] == f2[:size]
  equalcksum = f1[:digest] == f2[:digest]
  fcompare   = ( equalmagic && equalsizes && equalcksum )
  fcompare   = ( equaltimes && fcompare ) if options[:times]
  textfiles  = ( f1[:type] == 'text' && f2[:type] == 'text' )  # binary files

  if options[:verbose]
    $stdout.printf "   f1: %-40s %2s  f2: %-40s\n", f1[:name], diffsep( equaltimes ), f2[:name]
    if options[:times]
      $stdout.printf "    m| %-40s %2s   m| %-40s\n", f1[:mtime], diffsep( equaltimes ), f2[:mtime]
      $stdout.puts "   file1 is #{equaltimes ? 'older' : 'newer'} than file2" if options[:dependency]
      $stdout.printf "    a| %-40s --   a| %-40s\n", File.atime(f1[:name]), File.atime(f2[:name])
      $stdout.printf "    c| %-40s --   c| %-40s\n", File.ctime(f1[:name]), File.ctime(f2[:name])
    end  # if times
    $stdout.printf "  typ| %-40s %2s typ| %-40s\n", f1[:type], diffsep( equalmagic ), f2[:type]
    $stdout.printf "  siz| %-40s %2s siz| %-40s\n", f1[:size], diffsep( equalsizes ), f2[:size]
    d = options[:digest][0..2].downcase
    $stdout.printf "  #{d}| %-40s %2s #{d}| %-40s\n", f1[:digest], diffsep( equalcksum ), f2[:digest]
  end  # if options[:verbose]

  $stdout.puts "'#{fname1.bold}' #{diffsep( fcompare )} '#{fname2.bold}'"
  interactive_launch( fname1, fname2, textfiles, options ) if ! fcompare
  return fcompare  # true means "same", false means "different"
end  # fileComparison

def diffsep( cond )
  cond ? "==".bold.color(:green) : "<>".bold.color(:red)
end  # diffsep

# -----

def interactive_launch( fname1, fname2, textfiles, options )
  tools = {}
  quitcommands = %w{ no exit quit }
  # Setup readline completions vocabulary
  CANDIDATE_TOOLS.each do |c|
    ctool = app_installed?( c, options[:debug] )
    tools[File.basename( ctool )] = ctool if ctool
  end
  if tools.empty?
    $stderr.puts "%#{PROGNAME}-f-noapp, no 'diff' application found or installed"
    exit false
  end
  toolkeys = tools.keys
  availabletools = app_cmd_completions( toolkeys, exitquit: true, yesno: true )
  $stderr.puts "%#{PROGNAME}-w-not_text, filemagic analyzes non-text files" if !textfiles
  # Prompt user for "Which tool?" (or yes, continue)
  response = getprompted( "  * Launch a diff-tool on these files", "Yes" )
  response = availabletools[response.downcase]  # fully expand
  return true if response == 'no'  # ...done!

  difftool = response    # starting assumption: user has provided tool name?
  # Got an affirmative response or a tool name:
  if textfiles           # both files are text?
    if response == 'yes'   # ...but not a tool name, so figure defaults and ask:
      # Prefer the user-specified options[:tool] as the default diff-tool,
      # else just use kompare (if it's installed) or diff (always installed)
      defaulttool = availabletools[options[:tool]]  # user's choice installed?
      if ! defaulttool                              # nope: figure final default:
        defaulttool = toolkeys.find_index('kompare') ? 'kompare' : 'diff'
      end
      difftool = getprompted( "  * Diff-tool #{toolkeys.to_s.color(:dkgray)}", defaulttool )
      difftool = availabletools[difftool.downcase]  # fully expand
      # User may have decided to quit here...
      exit true if quitcommands.find_index( difftool )
    end
    # Final sanity-check the response -- is finally-chosen difftool in tools?
    if ! toolkeys.find_index( difftool )
      $stderr.puts "%#{PROGNAME}-f-unsupported, no such diff-tool '#{difftool}'"
      exit false
    end
  else
    # The only current/default choice for binary/non-text files,
    # unless user overrrides with a specific tool-choice:
    difftool = 'dhex' if difftool == 'y'
  end

  # Ready to execute something!  First, determine whether exec'ing or spawn'ing:
  chain_exec = EXEC_TOOLS.find_index( difftool )

  # Next, tweak a few special cases...
  case difftool.to_sym
  when :cmp  then diffopt = " -b --verbose"           # all bytes
  when :dhex then diffopt = " -f ~/.dhexrc"           # use a config-file
  when :diff then diffopt = " -yW#{options[:width]}"  # parallel, width
  else diffopt = ''
  end  # case

  cmd = "#{tools[difftool]}#{diffopt} '#{fname1}' '#{fname2}' 2>/dev/null"
  msg = "    $ #{cmd.underline.color(:blue)}"

  if chain_exec
    # These com-line tools can run directly in same XTerm session/context --
    sep = ('=' * options[:width]).color(:red)
    $stdout.puts "\n#{sep}\n#{msg}\n\n"
    exec( cmd )
  else
    # Launch these tools as child/subproc and as independent windows
    # (same as invoking from com-line, e.g.:  $ kompare & ) --
    $stdout.puts "#{msg} &"
    spawn( cmd )
  end
end  # interactive_launch
