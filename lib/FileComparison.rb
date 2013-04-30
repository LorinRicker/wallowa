#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# FileComparison.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.4, 10/24/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

def fileComparison( f1, f2, options )

  [ f1, f2 ].each_with_index do | f, i |
    if !File.exists?(f)
      puts "%filecomp-E-FNF, file f#{i+1} not found: #{f}"
      exit false
    end  # if !File.exists?(f)
  end

  # Rake file comparisons looks at File.mtime (not .ctime or .atime)

  f1_mtime  = File.mtime(f1)
  f1_size   = File.size(f1)
  f1_digest = File.msgdigest( f1, options[:digest] )

  f2_mtime  = File.mtime(f2)
  f2_size   = File.size(f2)
  f2_digest = File.msgdigest( f2, options[:digest] )
  if options[:dependency]
    # Files are mtime-dependent --
    # true: test that Src-file is _older_ than Tar-file
    # (like Rake's file-comparison trigger):
    eql_times = f1_mtime <= f2_mtime
  else
    # Files are mtime-equal --
    # false: test that f1's mtime equals f2's mtime:
    eql_times = f1_mtime == f2_mtime
  end  # if options[:dependency]
  separator = eql_times ? "==".bold.color(:green) : "->".bold.color(:red)
  eql_sizes = f1_size == f2_size
  eql_cksum = f1_digest == f2_digest
  fcompare  = ( eql_sizes && eql_cksum )
  fcompare  = ( eql_times && fcompare ) if options[:times]

  if options[:verbose]
    printf "   f1: %-40s %2s  f2: %-40s\n", f1, separator, f2
    if options[:times]
      printf "    m| %-40s %2s   m| %-40s\n",
        f1_mtime, separator, f2_mtime
      puts "   f1 is #{eql_times ? 'older' : 'newer'} than f2" if options[:dependency]
      printf "    a| %-40s --   a| %-40s\n",
        File.atime(f1), f2_exists ? File.atime(f2) : ""
      printf "    c| %-40s --   c| %-40s\n",
        File.ctime(f1), f2_exists ? File.ctime(f2) : ""
    end  # if times
    printf "  siz| %-40s -- siz| %-40s", f1_size, f2_size
    identag = "identical (" + "==".bold.color(:green) + ")"
    difftag = "different (" + "<>".bold.color(:red)   + ")"
    fcontents = eql_sizes ? identag : difftag
    puts "\n  File contents are #{fcontents} by file sizes"
    printf "  mdg| %-40s -- mdg| %-40s", f1_digest, f2_digest
    fcontents = eql_cksum ? identag : difftag
    puts "\n  File contents are #{fcontents} by msg-digest:#{options[:digest].upcase}"
  end  # if options[:verbose]

  return fcompare  # true means "same", false means "different"
end  # fileComparison
