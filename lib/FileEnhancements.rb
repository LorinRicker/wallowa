#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# FileEnhancements.rb
#
# Copyright © 2012-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.13, 10/28/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require 'fileutils'
require 'yaml'
#~ require 'pp'

ONEKILO = 2 ** 10  #                1024
ONEMEGA = 2 ** 20  #             1048576
ONEGIGA = 2 ** 30  #          1073741824
ONETERA = 2 ** 40  #       1099511627776
ONEPETA = 2 ** 50  #    1125899906842624
ONEEXA  = 2 ** 60  # 1152921504606846976

class File

# Some initializing things for owner_human_readable:
# Slurp up /etc/group file into hash { gid => group, ... }
@gids = Hash.new{ "" }
open( "/etc/group" ).each do | line |
  fields = line.split(':')
  @gids[fields[2].to_i] = fields[0]
end  # open( "/etc/group" )
# Likewise, slurp up /etc/passwd file into hash { uid => user, ... }
@uids = Hash.new{ "" }
open( "/etc/passwd" ).each do | line |
  fields = line.split(':')
  @uids[fields[2].to_i] = fields[0]
end  # open( "/etc/passwd" )
#~ pp @@gids
#~ pp @@uids

  # Compare this hack:
  # Getting file ownership info the system-expensive way:
  #   fowner = %x{stat --printf="%U:%G (%u,%g)" "#{f}"}

  # Translate a uid:gid integer pair into
  # human-readable strings "username:groupname"
  def self.translate_uid_gid( uid, gid )
    return "#{@uids[uid]}:#{@gids[gid]}"
  end  # translate_uid_gid

  # Translate a file's ownership (uid:gid integers) pair into
  # human-readable strings "username:groupname (uid:gid)"
  def self.owner_human_readable( fstat )
    uid = fstat.uid
    gid = fstat.gid
    ug  = translate_uid_gid( uid, gid )
    return ug + " (#{uid}:#{gid})"
  end  # owner_human_readable

  # Returns true if [uid,gid] fstat for file-resource (its ownership)
  # is equal to the [puid,pgid] for "this process"... false otherwise:
  def self.ownedby_user( fstat,
                         puid = Process::Sys.getuid,
                         pgid = Process::Sys.getgid )
    return ( puid == fstat.uid ) && ( pgid == fstat.gid )
  end  # ownedby_user

  # Like ls -h or --human-readable, produces file sizes in
  # human readable format (e.g., 1.1K, 2.2M, 3.3G, etc.)
  def self.size_human_readable( fsize )
    return fsize.to_s if fsize < ONEKILO
    case fsize
    when ONEKILO...ONEMEGA
      return sprintf( "%5.1fK", fsize.to_f / ONEKILO )
    when ONEMEGA...ONEGIGA
      return sprintf( "%5.1fM", fsize.to_f / ONEMEGA )
    when ONEGIGA...ONETERA
      return sprintf( "%5.1fG", fsize.to_f / ONEGIGA )
    when ONETERA...ONEPETA
      return sprintf( "%5.1fT", fsize.to_f / ONETERA )
    when ONETERA...ONEEXA
      return sprintf( "%5.1fP", fsize.to_f / ONEPETA )
    else
      return ">1Exa"
    end  # case fsize
  end  # size_human_readable

  # Hack: rather than convert the octal-integer to the appropriate
  #       "drwxrwxrwx" string, fork a call to shell's stat utility:
  #
  #       prot = %x{stat --printf="%A" "#{f}"}
  #
  # This is system-expensive (forks a sub-process for every call).
  # Better replaced by the following method...

  # Translate a file's mode (protection mask) integer value
  # into a readable string (e.g., 0644 = "-rw-r--r--" and
  # 755 = "-rwxr-xr-x")
  def self.mode_human_readable( fstat )
    m = fstat.mode
    perm = ""
    3.times do
      3.times do |i|
        perm = ( m % 2 == 1 ? "xwr"[i] : "-" ) + perm
        m >>= 1  # right-shift m one bit
      end  # 3.times
    end  # 3.times
    case fstat.ftype
    when "directory"
      perm = "d" + perm
    when "link"
      perm = "l" + perm
    else
      perm = "-" + perm
    end  # case
    return perm
  end  # mode_human_readable

  def self.mode_human_readable_VMS( fstat )
    perm = mode_human_readable( fstat )
    return perm[0] + ' O:' + perm[1..3] + ' G:' + perm[4..6] + ' W:' + perm[7..9]
  end  # mode_human_readable_VMS

  # Tack-on an explicit file extension if filename is missing one...
  def self.default_extension( fname, fext )
    fname += fext if extname( fname ) == ""
    return fname
  end  # default_extension

  # Decompose a filespec into its parts (basename, extension, dir-path),
  # substituting missing/implicit parts from fdef as needed and
  # available (like VMS/DCL f$parse, but in Linux filepath syntax);
  # return a hash containing the parts and the fully-expanded filespec
  # with substitutions.
  def self.parse( f, fdef = "." )
    # Break down original and default filespecs into components:
    wd      = Dir.getwd
    fdir    = dirname(f).chomp(wd).chomp('.')  # "" if == current working dir
    fext    = extname f
    fnam    = basename(f).chomp(fext)  # trim any ".ext"
    fd      = File.join( File.expand_path( fdef ), "*" )
    fdefdir = dirname fd
    fdefext = extname fd
    fdefnam = basename(fd).chomp('*'+fdefext).chomp(fdefext)  # trim...
    # Then glue it back together, replacing any missing original
    # component(s) with corresponding component(s) from default:
    g = ( fnam == "" ? fdefnam : fnam ) +
        ( fext == "" ? fdefext : fext )
    g = File.join( fdir == "" ? fdefdir : fdir, g )
    fullf = File.expand_path g
    # ...and build the return hash:
    fh = Hash.new( "" )
    fh[:full] = fullf
    dir       = dirname fullf
    fh[:dir]  = dir + ( dir[-1] != File::SEPARATOR ? File::SEPARATOR : "" )
    fh[:base] = basename fullf
    fh[:ext]  = extname fullf
    # chop leading '.'
    fh[:type] = fh[:ext] != "" ? fh[:ext][1..fh[:ext].size-1] : ""
    fh[:name] = basename(fullf).chomp(fh[:ext])
    return fh
  end  # parse

  # Given a filespec f1 on the command line (either absolute or relative),
  # check the next filespec f2: if it is merely a directory-spec, then
  # inherit f1's basename to fill-out f2:
  def self.inherit_basename( f1, f2 )
    f = File.directory?( f2 ) ? File.join( f2, File.basename( f1 ) ) : f2
    g = parse( f2, f1 )
    #~ puts "f: '#{f}' -- g: '#{g}'"
    return f
  end  # inherit_basename

  # Check the first line of a file for "shebang" information --
  # either (for example): "#!/usr/bin/ruby" or "#!/usr/bin/env ruby" --
  # return the programming/scripting language processor if present...
  def self.parse_shebang( fname )
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
  def self.msgdigest( f, dig = 'SHA1' )
    case dig
    when /MD5/i
      require 'digest/md5'
      Digest::MD5.hexdigest( File.binread( f ) )
    when /SHA256/i
      require 'digest/sha2'
      Digest::SHA256.hexdigest( File.binread( f ) )
    when /SHA384/i
      require 'digest/sha2'
      Digest::SHA384.hexdigest( File.binread( f ) )
    when /SHA512/i
      require 'digest/sha2'
      Digest::SHA512.hexdigest( File.binread( f ) )
    else  # default /SHA1/i
      require 'digest/sha1'
      Digest::SHA1.hexdigest( File.binread( f ) )
    end  # case
  end  # msgdigest

  # Verify & report the "Unix magic number" file identification signature
  def self.verify_magicnumber( fname, fext = nil, echo = nil )
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

  # While File.readlink behaves like the analogous shell command,
  # File.readlink! behaves like 'readlink --canonicalize (-f)',
  # i.e., follow every symlink recursively; all but the last file
  # component must exist:
  def self.readlink!(path)
    path = File.expand_path(path)
    dirname = File.dirname(path)
    readlink = File.readlink(path)
    if not readlink =~ /^\// # it's a relative path
      readlink = dirname + '/'+ readlink # make it absolute
    end
    readlink = File.expand_path(readlink) # eliminate this/../../that
    if File.symlink?(readlink)
      return File.readlink!(readlink) # recursively follow symlinks
    else
      return readlink
    end
  end  # File.readlink!

end  # class File

class AppConfig

  # Verify the existence of an app-specific directory for a configuration
  # file in ~/home, create it if it's missing.
  def self.check_yaml_dir( confdir, perms = 0700 )
    Dir.mkdir( confdir, perms ) if ! Dir.exists?( confdir )
  end  # check_yaml_dir

  # Save or (re)load an app-specific configuration file (YAML).
  def self.configuration_yaml( cfile, config, force_save = false )
    check_yaml_dir( File.dirname(cfile) )
    if ! force_save && File.exists?( cfile )
      return YAML.load_file( cfile )
    else
      File.open( cfile, 'w' ) { |f| YAML::dump( config, f ) }
      $stderr.puts "%YAML-i-init, config-file #{cfile} initialized"
      return {}
    end  # if File.exists? cfile
  end  # configuration_yaml

end  # class AppConfig
