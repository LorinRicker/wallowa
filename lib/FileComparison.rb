#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# FileComparison.rb
#
# Copyright © 2011-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 02/02/2015
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

def fileComparison( fname1, fname2, options )

  [ fname1, fname2 ].each_with_index do | f, i |
    if !File.exists?(f)
      puts "%filecomp-e-fnf, file#{i+1} not found: #{f}"
      exit false
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
  ftext      = ( f1[:type] == 'text' && f2[:type] == 'text' )  # binary files

  if options[:verbose]
    printf "   f1: %-40s %2s  f2: %-40s\n", f1[:name], separator( equaltimes ), f2[:name]
    if options[:times]
      printf "    m| %-40s %2s   m| %-40s\n", f1[:mtime], separator( equaltimes ), f2[:mtime]
      puts "   file1 is #{equaltimes ? 'older' : 'newer'} than file2" if options[:dependency]
      printf "    a| %-40s --   a| %-40s\n", File.atime(f1[:name]), File.atime(f2[:name])
      printf "    c| %-40s --   c| %-40s\n", File.ctime(f1[:name]), File.ctime(f2[:name])
    end  # if times
    printf "  typ| %-40s %2s typ| %-40s\n", f1[:type], separator( equalmagic ), f2[:type]
    printf "  siz| %-40s %2s siz| %-40s\n", f1[:size], separator( equalsizes ), f2[:size]
    d = options[:digest][0..2].downcase
    printf "  #{d}| %-40s %2s #{d}| %-40s\n", f1[:digest], separator( equalcksum ), f2[:digest]
  end  # if options[:verbose]

  report( fname1, fname2, fcompare, ftext, options )
  return fcompare  # true means "same", false means "different"
end  # fileComparison

# -----

def separator( cond )
  cond ? "==".bold.color(:green) : "<>".bold.color(:red)
end  # separator

def report( fname1, fname2, fcompare, ftext, options )
  puts "'#{fname1}' #{separator( fcompare )} '#{fname2}'"
  ask_diff( fname1, fname2, ftext, options ) if ! fcompare
  # User will exit getprompted() with Ctrl-D or Ctrl-Z,
  # which _always_exits_with_ status:0 ...
end  # report

def ask_diff( f1, f2, ftext, options )
  if askprompted( "Launch a diff-tool on these files" )
    progname, launchstr = which_diff( ftext, options )
    cmd = "#{launchstr} '#{f1}' '#{f2}'"
    msg = "launching #{progname.underline.color(:dkgray)}..."
    sep = ('=' * options[:width]).color(:red)
    if EXEC_TOOLS.index(progname.split(' ')[0])
      # These com-line tools can run directly in same XTerm session/context --
      puts "\n#{sep}\n#{msg}\n\n"
      exec( cmd )
    else
      # Launch these tools as child/subproc and as independent windows
      # (same as invoking from com-line, e.g.:  $ kompare & ) --
      puts msg
      spawn( cmd )
    end
  end
end  # ask_diff

def which_diff( ftext, options )
  # Test: is the candidate-app installed?  If so, add it to diffs array:
  diffs = []
  if ftext
    CANDIDATE_TOOLS.each { |c| diffs << c if is_app_installed?( c, options ) }
    # Setup readline completions vocabulary, and prompt user for "Which app?"
    difftools = app_cmd_completions( diffs )
    # Prefer the user-spec'd options[:diff] as the default diff-tool,
    # else just use kompare (if its installed) or diff (always installed)...
    if not ( defdiff = difftools[options[:diff]] )  # assignment!!
      defdiff = diffs.index('kompare') ? 'kompare' : 'diff'
    end
    diff = getprompted( "Diff-tool #{diffs.to_s.color(:dkgray)}", defdiff )
    diff = difftools[diff]  # Get fully-expanded command from hash...
    exit true if diff == "exit" || diff == "quit"
    # User could have entered "foobar" for all we know...
    # sanity-check the response -- is diff in diffs?
    if not diffs.index( diff )
      $stderr.puts "%#{PROGNAME}-e-unsupported, no such diff-tool '#{diff}'"
      exit true
    end
  else
    diff = 'dhex'  # the only current choice for binary/non-text files
  end
  case diff.to_sym  # a couple of special cases...
  when :cmp  then diff = "#{diff} -b --verbose"           # all bytes
  when :dhex then diff = "#{diff} -f ~/.dhexrc"
  when :diff then diff = "#{diff} -yW#{options[:width]}"  # parallel, width
  end  # case
  return [ diff, "/usr/bin/#{diff.downcase} 2>/dev/null" ]
end  # which_diff

def is_app_installed?( app, options )
  response = %x{ whereis #{app} }.chomp.split(' ')
  puts "$ whereis #{app}: #{response}" if options[:verbose]
  return response[1] != nil
end  # is_app_installed?
