#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# stripcomments.rb
#
# Copyright © 2014-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Strips (removes) comment lines from a source-code file; removes both
#   stand-alone (single-line) comments and those embedded in source lines.
# Uses STDIN and STDOUT, filenames on com-line, including redirection,
#   so this program can be used as a filter in a pipeline...
#
# Usage:  $ ./stripcomments [infile] [outfile]
#         $ ./stripcomments foo.rb                  # output to STDOUT
#         $ ./stripcomments foo.rb foo.nocomments
#         $ ./stripcomments <foo.rb >foo.nocomments
#         $ cat foo.rb | ./stripcomments | wc -l

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.2 02/10/2015"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

COMMENTMARK = '#'   # for Ruby, Perl, Python & bash (etc.) source files

STDINFD  = 0
STDOUTFD = 1

def prepare( outfile )
  if outfile
    outf = File.open( outfile, 'w' )
  else
    outf = File.new( STDOUTFD, 'w' )
  end
rescue Errno::ENOENT => e
  STDERR.puts "%#{PROGNAME}-e-fnf, error opening output file (no such dir/path)"
  exit false
rescue IOError => e
  STDERR.puts "%#{PROGNAME}-e-errout, error opening output file or stream"
  exit false
end

def process( inputf, outf )
  compat = /#[^{]/   # don't count str-interpolation "#{var}" as a comment!
  File.open( inputf ? inputf : STDINFD, "r") do | inf |
    while line = inf.gets
      line = line.chomp
      next if line.lstrip[0] == COMMENTMARK
      line = line.split( COMMENTMARK )[0].rstrip if line.index( compat )
      outf.puts line
    end
  end
rescue Errno::ENOENT => e
  STDERR.puts "%#{PROGNAME}-e-fnf, error opening input file '#{inputf}'"
  exit false
end

process( ARGV[0], prepare( ARGV[1] ) )
# better than:
#    outf = prepare( ARGV[1] )
#    process( ARGV[0], outf )
