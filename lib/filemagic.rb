#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# filemagic.rb
#
# Copyright © 2011-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.1, 06/27/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# -----

module FileMagic

  # Check the first line of a file for "shebang" information --
  # either (for example): "#!/usr/bin/ruby" or "#!/usr/bin/env ruby" --
  # return the programming/scripting language processor if present...
  def parse_shebang
    fname = self
    fn = File.expand_path( fname )
    pl = ""
    begin
      File.open( fn, "r" ) do | f |
        line1 = f.gets
        if line1[0..1] == "#!"
          fn = line1[2..-1].split
          # ...either '/usr/bin/ruby' or '/usr/bin/env ruby'
          pl = File.basename( fn[0] )
          pl = fn[1] if pl == "env"
        end  # if
      end # File.open
    rescue Exception  # typically, FNF-file not found
      return nil
    end
    return pl
  end  # parse_shebang

  # Calculate and produce a Message Digest for a file...
  def msgdigest( dig = 'SHA1' )
    fname = self
    case dig
    when /MD5/i
      require 'digest/md5'
      Digest::MD5.hexdigest( File.binread( fname ) )
    when /R.*160/i  # RIPEMD-160
      require 'digest/rmd160'
      Digest::RMD160.hexdigest( File.binread( fname ) )
    when /SHA256/i
      require 'digest/sha2'
      Digest::SHA256.hexdigest( File.binread( fname ) )
    when /SHA384/i
      require 'digest/sha2'
      Digest::SHA384.hexdigest( File.binread( fname ) )
    when /SHA512/i
      require 'digest/sha2'
      Digest::SHA512.hexdigest( File.binread( fname ) )
    when /SHA1/i
      require 'digest/sha1'
      Digest::SHA1.hexdigest( File.binread( fname ) )
    else
      STDERR.puts "%filemagic-e-bad_msgdigest, no such message digest \"#{dig}\""
      exit false
    end  # case
  end  # msgdigest

  # Use standard file utility to determine file-type by magic number
  def filemagic
    fname = self
    magic = Array.new
    # The code specification (and man-page) for the file utility stipulate that
    # its output *must* include one of the words 'text', 'executable' or 'data'
    # for each file examined. However, it looks like this "standard" has been
    # ignored for years, so any output which fails to include one of these key
    # words has to be categorized as "unkn[own]", unless special cases can be
    # determined --
    cmd = "/usr/bin/file -bL '#{fname}'"
                         # --brief, just the file-type text-report is output
                         # --dereference, follow any symlink to file
    magic[1] = %x{ #{cmd} }.chomp.strip
    stat = $?.exitstatus
    if stat == 0
      case magic[1]
      when /\btext\b/i
        magic[0] = 'text'
      when /\bexecutable\b/i, /\bbyte-compiled\b/i
        magic[0] = 'exec'
      when /\bdata\b/i, /\bdatabase\b/i, /\bdocument\b/i
        magic[0] = 'data'
      when /\bempty\b/i
        magic[0] = 'empty'
      else
        magic[0] = 'unknown'
      end  # case
      return magic  # ['file-original-type-msg','category']
    else
      $stderr.puts "%file_magic-e-fnf, cannot do: '#{cmd}'"
      return [nil,nil]
    end
  end  # filemagic

  # Verify & report the "Unix magic number" file identification signature
  def verify_magicnumber( fext = nil, echo = nil )
    fname = self
    ext = fext || extname( fname )
    lext = ext.length
    ext = ext[0] == "." ? ext[1..lext] : ext
    case ext.downcase
      when "mp3"    # "ID3"
        filsig = "\x49\x44\x33"
        begsig = 0
        siglen = 3
      when "wav"    # "RIFF"
        filsig = "\x52\x49\x46\x46"
        begsig = 0
        siglen = 4
      when "ogg", "oga", "ogv", "ogx"     # "OggS"
        filsig = "\x4F\x67\x67\x53"
        begsig = 0
        siglen = 4
      when "pdf"    # "%PDF"
        filsig = "\x25\x50\x44\x46"
        begsig = 0
        siglen = 4
      when "tff", "tiff"  # "I I"
        filsig = "\x49\x20\x49"
        begsig = 0
        siglen = 3
      when "gif"    # "GIF89a" or "GIF87a"
        filsig = "\x47\x49\x46\x38\x39\x61"   # or "\x47\x49\x46\x38\x37\x61"
        begsig = 0
        siglen = 6
      when "iso"    # "CD001"
        filsig = "\x43\x44\x30\x30\x31"
        begsig = 0
        siglen = 5
      #when "mp4"   # «+»
      #  filsig = "\x«+»"
      #  begsig = 0
      #  siglen = 3
      #when "jpg"   # using EXIF Exchangeable Image File Format
      #  filsig = "\xFF\xD8\xFF\xE0 xx xx \x45\x78\x69\x66\x00" # "ÿØÿá??Exif."
    # or filsig = "\xFF\xD8\xFF\xE0 xx xx \x4A\x46\x49\x46\x00" # "ÿØÿá??JFIF."
      #  begsig = 0
      #  siglen = 3
      #when "«+»"     # «+»
      #  filsig = "\x«+»"
      #  begsig = 0
      #  siglen = «+»
    end  # case ext.downcase
    begin
      # Return the signature string if the file's verified, else return nil:
      File.open( fname, "rb" ) do |f|
        sig = f.read( 64 )  # ...a big enough hunk
        if echo
          afs = ""
          sig[begsig,siglen].bytes.each { |b| afs << "#{sprintf("\\x%2X",b)}" }
          puts "Actual File Signature: #{afs}"
        end  # if echo
        return filsig if sig[begsig,siglen] == filsig
      end  # File.open( fname, ... )
    rescue NoMethodError
      return nil
    rescue Exception => e
      pp e
      print e.backtrace.join( "\n" )     # Catch-all, display the unexpected...
      return nil
    end
  end  # verify_magicnumber

end  # module

class String
  include FileMagic
end  # class
