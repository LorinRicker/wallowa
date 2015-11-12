#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# helloworld_ml.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# Multi-lingual "Hello, World!" on steroids
#   -- demonstrates com-line option parsing

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.01 (07/11/2014)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

require 'optparse'

options = {}

optparse = OptionParser.new { |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options]" +
              "\n       Demonstrates multi-lingual 'Hello, World!' output"
  opts.on( "-?", "-h", "--help", "Display this help text" ) do |val|
    puts opts
    options[:help] = true
    exit true
  end  # -? --help
  opts.on( "-a", "--about", "Display program info" ) do |val|
    puts "#{PROGID}"
    puts "#{AUTHOR}"
    options[:about] = true
    exit true
  end  # -a --about
  opts.on( "-l", "--language", "=LANGUAGE",
           /english|french|german|italian|spanish/i,
           "Language: English (d), French, German, Italian, Spanish" ) do |val|
    options[:language] = val.downcase || "english"
  end  # -l --language
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --debug
  opts.on( "-d", "--debug", "Debug mode (more output than verbose)" ) do |val|
    options[:debug] = true
  end  # -d --debug
}.parse!  # leave residue-args in ARGV

puts case options[:language]
      when 'french'
        'Bonjour, tout le monde!'
      when 'german'
        'Hallo, Welt!'
      when 'italian'
        'Ciao, mondo!'
      when 'spanish'
        '¡Hola, Mundo!'
      else
        'Hello, World!'
      end  # case
