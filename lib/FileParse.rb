#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# FileParse.rb
#
# Copyright © 2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 06/03/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Refactored all file-parse related methods from lib/FileEnhancements.rb (06/03/2017)

class File

  # Return file elements all parsed out:
  # [ directorypath, filename, filetype, expandedfilespec ]
  # use:  dirpath, fname, ftype, fullspec = fileparse( filespec )
  def self.fileparse( fspec )
    fspec = File.expand_path( fspec )
    fdirn = File.dirname( fspec )
    ftype = File.extname( fspec )
    fname = File.basename( fspec, ftype )
    [ fdirn, fname, ftype, fspec ]
  end # fileparse

  # # Decompose a filespec into its parts (basename, extension, dir-path),
  # # s+ubstituting missing/implicit parts from fdef as needed and
  # # available (like VMS/DCL f$parse, but in Linux filepath syntax);
  # # return a hash containing the parts and the fully-expanded filespec
  # # with substitutions.
  # def self.parse( f, fdef = "." )
  #   # Break down original and default filespecs into components:
  #   wd      = Dir.getwd
  #   fdir    = dirname(f).chomp(wd).chomp('.')  # "" if == current working dir
  #   fext    = extname f
  #   fnam    = basename(f).chomp(fext)  # trim any ".ext"
  #   fd      = File.join( File.expand_path( fdef ), "*" )
  #   fdefdir = dirname fd
  #   fdefext = extname fd
  #   fdefnam = basename(fd).chomp('*'+fdefext).chomp(fdefext)  # trim...
  #   # Then glue it back together, replacing any missing original
  #   # component(s) with corresponding component(s) from default:
  #   g = ( fnam == "" ? fdefnam : fnam ) +
  #       ( fext == "" ? fdefext : fext )
  #   g = File.join( fdir == "" ? fdefdir : fdir, g )
  #   fullf = File.expand_path g
  #   # ...and build the return hash:
  #   fh = Hash.new( "" )
  #   fh[:full] = fullf
  #   dir       = dirname fullf
  #   fh[:dir]  = dir + ( dir[-1] != File::SEPARATOR ? File::SEPARATOR : "" )
  #   fh[:base] = basename fullf
  #   fh[:ext]  = extname fullf
  #   # chop leading '.'
  #   fh[:type] = fh[:ext] != "" ? fh[:ext][1..fh[:ext].size-1] : ""
  #   fh[:name] = basename(fullf).chomp(fh[:ext])
  #   return fh
  # end  # parse

  # Given a filespec f1 on the command line (either absolute or relative),
  # check the next filespec f2: if it is merely a directory-spec, then
  # inherit f1's basename to fill-out f2:
  def self.inherit_basename( f1, f2 )
    f = File.expand_path( f2 )
    f = File.directory?( f ) ? File.join( f, File.basename( f1 ) ) : f
    g = parse( f, f1 )
    #~ puts "f: '#{f}' -- g: '#{g}'"
    return f
  end  # inherit_basename

  # Tack-on an explicit file extension if filename is missing one...
  def self.default_extension( fname, fext )
    fname += fext if extname( fname ) == ""
    return fname
  end  # default_extension

  # Given a filespec (typically user-entered), check if it
  # includes any of the characters * - ? - [] - {} which can
  # be used with File.glob.  If wildcards not found, just
  # return false, else return true, and optionally annunciate
  # error message, and optionally exit with error status.
  def self.wildcarded?( f, errmsg = nil, abort = false )
  any_wild = f.match( /[\*\?\[\]\{\}]/ )
  if any_wild
    $stderr.puts errmsg if errmsg.kind_of?( String )
    exit false if abort
  end
  return any_wild
  end  # wildcarded?

end  # class File
