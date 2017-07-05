#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# fspec.rb
#
# Copyright © 2017 Lorin Ricker <lorin@rickernet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# fspecs-- Derives a VMS and *nix file specification, given the other one.

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v0.2 (07/05/2017)"
  AUTHOR = "Lorin Ricker, Elbert, Colorado, USA"

DBGLVL0 = 0
DBGLVL1 = 1
DBGLVL2 = 2  ######################################################
DBGLVL3 = 3  # <-- reserved for binding.pry &/or pry-{byebug|nav} #
             ######################################################
# -----

require 'optparse'
require_relative 'lib/WhichOS'

# ==========

# === Main ===
options = { :noop    => false,
            :update  => false,
            :verbose => false,
            :debug   => DBGLVL0,
            :about   => false
          }

optparse = OptionParser.new { |opts|
  # opts.on( "-«+»", "--«+»",  # "=«+»", String,
  #          "«+»" ) do |val|
  #   options[:«+»] = «+»
  # end  # -«+» --«+»
  # opts.separator ""
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
    $stdout.puts "#{PROGID}"
    $stdout.puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  # --- Set the banner & Help option ---
  opts.banner = "\n  Usage: #{PROGNAME} [options] file [ file ]..." +
                "\n\n  where each file argument is either a VMS (OpenVMS) or a *nix (Linux or Unix)" +
                "\n  file specification or file path-spec to convert into 'the other' style of" +
                "\n  filespec.  This permits comparison of how VMS handles both syntaxes.\n\n"
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

case WhichOS.identify_os
when :vms
  require 'DECC'
  vmspat = Regexp.new( /[:;\[\]]+/ )
        # /\A([^:;.,\/\\]*:)?(\[[^:;.,\]\/\\]*\])?([^:;.,\/\\]*)?\.([^:;.,\/\\]*)?(;\d*)?\z/i )
                                   # All fields optional, negated char-classes
         # \A                      #   generally exclude .:;,/\ --
         # ([^:;.,\/\\]*:)?        # DEVICE: (any-chars up to :)
         # (\[[^:;.,\]\/\\]*\])?   # [DIRECTORY.SUB1...] (any-chars between [])
         # ([^:;.,\/\\]*)?         # FILENAME (any-chars up to .)
         # \.([^:;.,\/\\]*)?       # . then FILETYPE (any-chars up to ;)
         # (;\d*)?                 # ;VERSION (0 or more digits following ;)
         # \z/xi )
  nixpat = Regexp.new( /\/+/ )
        #  /\A(\/|\\)?([^\/\\\[\]:;]*(\/|\\)?)+(\/|\\)?\z/xi )
        #  \A
        #  (\/|\\)?                # Optional leading / (or \)
        #  ([^\/\\\[\]:;]*         # Most anything that does not look VMS-ish
        #   (\/|\\)?
        #  )+
        #  (\/|\\)?                # Optional trailing / (or \)
        #  \z', Regexp::EXTENDED | Regexp::IGNORECASE )
  ARGV.each do | fs |
    $stdout.puts "\ngiven: #{fs}"
    case fs
    when vmspat
      # Translate the VMS-style file-pec into *nix:
      nix_fs = DECC::from_vms( fs )
      $stdout.puts " *nix: #{nix_fs}"
    when nixpat
      # Translate the *nix-style filespec into VMS:
      vms_fs = DECC::to_vms( fs )
      $stdout.puts "  VMS: #{vms_fs}"
    else
      $stdout.puts "Simple or empty file specification, no VMS-*nix distinction"
    end
  end  # ARGV.each...
else
  STDERR.puts "%#{PROGNAME}-e-wrong_os, this program is designed for VMS (OpenVMS) only"
end  # case WhichOS...

exit true
