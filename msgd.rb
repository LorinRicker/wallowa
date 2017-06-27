#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# msgd.rb
#
# Copyright © 2016-2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# VMS (OpenVMS) has a CHECKSUM command, but its best message digest
# algorithm is (currently) MD5.  Cannot do SHA*, etc.
#
# But wait -- with VMS Ruby, we've got more!  Why not implement the
# advanced message digest algorithms with Ruby for VMS?

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.0 (06/25/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################

USAGE_MSG = "  Usage: #{PROGNAME} [options] file1 [ file2 ]..."

VMSONLY_BORDER    = ' ' * 4 + "=== VMS only " + '=' * 70
VMSONLY_BORDEREND = ' ' * 4 + '=' * ( VMSONLY_BORDER.length - 4 )

require 'optparse'
require 'pp'
require_relative 'lib/WhichOS'
require_relative 'lib/filemagic'
## require_relative 'lib/TermChar'

# ==========


# === Main ===
options = { :digest    => nil,
            :check     => false,
            :noop      => false,
            :verbose   => false,
            :debug     => DBGLVL0,
            :about     => false
          }

optparse = OptionParser.new { |opts|
  # --- Program-Specific options ---
  opts.on( "-s", "--digest[=DIGEST]", /SHA1|SHA256|SHA384|SHA512|MD5|R.*MD160/i,
           "Message digest to use:",
           "  MD5 (d), SHA[256,384,512], SHA1 or R[IPEMD]160" ) do |val|
  options[:digest] = val || "MD5"
  end  # -s --digest
  opts.on( "-c", "--check",
           "Red msg-digest(s) from file(s) and cross-check them;",
          "  file1 [file2]... must be message-digest output files" ) do |val|
    options[:check] = true
  end  # -r --variable

  opts.separator "\n#{VMSONLY_BORDER}"
  # opts.on( "-s", "--scope[=DCLSCOPE]", /GLOBAL|LOCAL/i,
  #          "DCL variable scope (default LOCAL, or GLOBAL)" ) do |val|
  #   options[:dclscope] = ( val || "LOCAL" ).upcase[0] == "L" ?
  #                          DCLSCOPE_LOCAL : DCLSCOPE_GLOBAL
  # end  # -x --scope
  opts.separator "\n    Options here are ignored if not VMS (OpenVMS)\n#{VMSONLY_BORDEREND}\n\n"

  opts.on( "-n", "--noop", "--dryrun", "--test",
           "Dry-run (test & display, no-op) mode" ) do |val|
    options[:noop]  = true
    options[:verbose] = true  # Dry-run implies verbose...
  end  # -n --noop
  # --- Verbose option ---
  opts.on( "-v", "--verbose", "--log", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
  # --- Debug option ---
  opts.on( "-d", "--debug", "=DebugLevel", Integer,
           "Show debug information (levels: 1, 2 or 3)",
           "  1 - enables basic debugging information",
           "  2 - enables advanced debugging information",
           "  3 - enables (starts) pry-byebug debugger" ) do |val|
    options[:debug] = val.to_i
  end  # -d --debug
  # --- About option ---
  opts.on_tail( "-a", "--about", "Display program info" ) do |val|
    require_relative 'lib/AboutProgram'
    options[:about] = about_program( PROGID, AUTHOR, true )
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n#{USAGE_MSG}" +
                "\n\n    where file1 ..." +
                "\n    xxx.\n\n"
  opts.on_tail( "-?", "-h", "--help", "Display this help text" ) do |val|
    $stdout.puts opts
    # $stdout.puts "«+»Additional Text«+»"
    options[:help] = true
    exit true
  end  # -? --help
}.parse!  # leave residue-args in ARGV

###############################
if options[:debug] >= DBGLVL3 #
  require 'pry'               #
  binding.pry                 #
end                           #
###############################

options[:os] = WhichOS.identify_os

pp options if options[:debug] >= DBGLVL2

mdpat = Regexp.new( /.*(SHA1|SHA256|SHA384|SHA512|MD5|RIPEMD160|RMD160).*/i )

failed_count = 0

if ARGV.length > 0
  if options[:check]  # check existing *.mdigest file against actual source file(s) --
    ARGV.each do | cname |
      lines = IO.readlines( cname )
      lines.each do | line |
        cdigest, fname = line.split
        if ( ! options[:digest] )
          fext = File.extname( cname )
          if m = mdpat.match( fext )  # assignment, not equality-test!
            options[:digest] = m[0][1..m.length+1].upcase
            STDERR.puts "%#{PROGNAME}-i-matched, auto-matched message digest #{m[0]}" if options[:verbose]
          else
            STDERR.puts "%#{PROGNAME}-e-nomatch, failed to auto-match any message digest"
            exit false
          end
        end  # if
        mdigest = fname.msgdigest( options[:digest] )
        if mdigest == cdigest
          STDOUT.puts "#{fname}: OK"
        else
          STDOUT.puts "#{fname}: FAILED"
          failed_count += 1
        end
      end  # lines.each
    end  # ARGV.each
    if failed_count > 0
      msg = "#{PROGNAME}: WARNING: #{failed_count} computed checksum" +
            "#{failed_count > 1 ? 's' : ''} did NOT match"
      STDOUT.puts msg
    end  # if failed_count > 0
  else  # generate "msgdigest  filename" output(s), which can be redirected --
    ARGV.each do | fname |
      fname = File.expand_path( fname ) if File.dirname( fname ) != '.'
      mdigest = fname.msgdigest( options[:digest] )
      STDOUT.puts "#{mdigest}  #{fname}"
    end  # ARGV.each
  end
else
  STDOUT.puts USAGE_MSG
end

exit true
