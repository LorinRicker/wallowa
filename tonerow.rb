#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# tonerow.rb
#
# Copyright © 2013 Lorin Ricker <Lorin@RickerNet.us>
# Version info: see PROGID below...
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

# ===========
# The very first version of this program was written at Purdue University in ~1972-73,
# in FORTRAN, as part of my undergraduate studies in Interdisciplinary Engineering
# (acoustics, music, electronic/computer music synthesis, EE, ME, etc.); I next recast
# a version of this in the late 1970s (at ESI) in Pascal.
#
# This Ruby version is an attempt, three decades later, to recapture the algorithm and
# utility, improving a bit on its generality (i.e., not strictly for a 12-tone row matrix,
# but now capable of generating a matrix for an arbitrary-sized tone row).
#
# References:
#   http://en.wikipedia.org/wiki/Twelve_tone_technique
#          en.wikipedia.org/wiki/Tone_row
#          en.wikipedia.org/wiki/Permutation_(music)
#          en.wikipedia.org/wiki/Set_theory_(music)
#
# Facts and assumptions:
#   i) Based on Western twelve tones to the octave; dodecaphonic.
#  ii) There are N! rows of N unique notes, so for twelve-tone music,
#      using all 12 tones (pitch classes) of the Western standard
#      octave, there are 12! = 479,001,600 rows, but 469,022,400
#      of these are merely transformations of other rows, so there
#      are 9,979,200 truly unique twelve-tone rows possible (rows
#      unrelated to any other through transposition, inversion,
#      retrograde, and retrograde inversion).
# iii) Pitch classes are numbered starting with C: 0, specifically
#          C: 0  C♯|D♭: 1      D: 2  D♯|E♭: 3      E: 4  F: 5
#      F♯|G♭: 6      G: 7  G♯|A♭: 8      A: 9  A♯|B♭: Д  B: ξ
#      where Д: 10 and ξ: 11

PROGNAME = File.basename $0
  PROGID = "#{PROGNAME} v1.03 (12/02/2013)"
  AUTHOR = "Lorin Ricker, Castle Rock, Colorado, USA"

# === For command-line arguments & options parsing: ===
require 'optparse'        # See "Pickaxe v1.9", p. 776
require 'pp'
require_relative 'ANSIseq'

# ==========

class RowSizeError < RuntimeError
end
class DiagonalError < RuntimeError
end

class ToneRow < Array

  TONES = 12  # standard twelve-note octave
  # Use UTF-8 characters to represent pitch-classes 10 and 11
  # in row outputs; command-line will use [DdEe] as convenient
  # input-entry substitutes:
  DEC = 'Д'
  ELF = 'ξ'
  # ...other contenders: δ ε ξ Д Є
  INDENT = 4
  SPC    = ' '

  def self.interval( prime, rsize )
    oint = Array.new( rsize-1 )
    i = 0
    while i < rsize - 1
      oint[i] = prime[i+1] - prime[i]
      i += 1
    end
    return oint
  end

  def self.inverse( prime, interval, rsize )
    oinv = Array.new( rsize )
    i = 1
    oinv[0] = prime[0]
    while i < rsize
      oinv[i] = ( oinv[i-1] - interval[i-1] ) % TONES
      i += 1
    end
    return oinv
  end

  def self.diagonalcheck( rmat )
    # The square (NxN) RowMatrix is calculated correctly iff
    # rowmatrix[0][0] == rowmatrix[1][1] == ... rowmatrix[N][N]
    k = 1
    while k < rmat[0].size
      return false if rmat[k][k] != rmat[0][0]
      k += 1
    end
    return true
  end

  def self.rowmatrix( prime, inverse, interval, rsize )
    # Create a static RxR (e.g., 12x12) array:
    rmat = Array.new( rsize ){Array.new( rsize )}
    rmat[0] = prime
    j = 1
    i = 1
    # Column-1: rowmatrix[...,0] = inverse of prime row
    while j < rsize
      rmat[j][0] = inverse[i]
      j += 1
      i += 1
    end
    # All other rows in rowmatrix are transpositions of
    # the prime row onto initial pitch of column-1,
    # the inverse row...
    i = 1
    while i < rsize
      j = 1
      transpo = rmat[i][0] - rmat[0][0]
      while j < rsize
        rmat[i][j] = ( rmat[0][j] + transpo ) % TONES
        j += 1
      end
      i += 1
    end
    return rmat
  end

  attr_reader :prime, :rsize, :retrograde, :intervals,
              :inverse, :invretro, :rowmatrix

  def initialize( rawrow, options )
    STDERR.puts "  raw row: '#{rawrow}'" if options[:verbose]
    if options[:rowsize]
      if options[:rowsize] != rawrow.size
        raise RowSizeError
      end
    end
    @prime = rawrow.split( '' ).collect { |d|
      d.upcase == 'D' ? 10 : d.upcase == 'E' ? 11 : d.to_i }
    STDERR.puts "    prime: #{@prime.to_s}" if options[:verbose]
    @rsize      = @prime.size
    @retrograde = @prime.reverse
    @interval   = ToneRow.interval( @prime, @rsize )
    STDERR.puts " interval: #{@interval.to_s}" if options[:verbose]
    @inverse    = ToneRow.inverse( @prime, @interval, @rsize )
    STDERR.puts "  inverse: #{@inverse.to_s}" if options[:verbose]
    @invretro   = @inverse.reverse
    STDERR.puts " invretro: #{@invretro.to_s}" if options[:verbose]
    @rowmatrix  = ToneRow.rowmatrix( @prime, @inverse,
                                     @interval, @rsize )
    raise DiagonalError if options[:diagonal] &&
                          !ToneRow.diagonalcheck( @rowmatrix )
    if options[:verbose]
      STDERR.puts "rowmatrix ===== "
      @rowmatrix.each { | r | STDERR.puts "  #{r.inspect}" }
    end
    return @rowmatrix
  end

  def self.to_pitchrow( row, ind = INDENT )
    str = SPC * ind
    row.each do | p |
      str += SPC + ( p == 10 ? DEC : p == 11 ? ELF : p.to_s )
    end
    return str
  end

  def self.report( rmat, prime, retrograde,
                   inverse, invretro, options )
    ind = SPC * INDENT
    STDOUT.print "\n #{options[:title]} --\n\n" if options[:title]
    rmat.each { | r | STDOUT.puts to_pitchrow( r ) }
    STDOUT.puts "\n#{ind}     Prime:#{to_pitchrow(prime,1)}" +
                "\n#{ind}Retrograde:#{to_pitchrow(retrograde,1)}"
    STDOUT.puts "#{ind}   Inverse:#{to_pitchrow(inverse,1)}" +
                "\n#{ind}  InvRetro:#{to_pitchrow(invretro,1)}"
  end

end  # class ToneRow

# ==========

options = {} # hash for all com-line options:

optparse = OptionParser.new { |opts|
  # Set the banner:
  opts.banner = "Usage: #{PROGNAME} [options] input-row >outfile"
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
  opts.on( "-d", "--diagonal", "Invoke diagonal check" ) do |val|
    options[:diagonal] = true
  end  # -d --diagonal
  opts.on( "-r", "--rowsize SIZE", Integer,
           "Specify row-size to verify input row size" ) do |val|
    options[:rowsize] = val
  end  # -r --remove
  opts.on( "-t", "--title TITLE", String,
           "RowMatrix report title" ) do |val|
    options[:title] = val
  end  # -t --title
  opts.on( "-v", "--verbose", "Verbose mode" ) do |val|
    options[:verbose] = true
  end  # -v --verbose
}.parse!

# User input row may be a single string: 0123456789de
# or it might be arbitrarily spaced: 0 1 2 3456 7 8 9de
# ...handle it any way it comes:

rawrow = ""  # establish scope...
ARGV.each { |a| rawrow << a }

begin
  rm = ToneRow.new( rawrow, options )
rescue RowSizeError
  puts "%#{PROGNAME}-E-ROWSIZE, specify a row of size #{options[:rowsize]}"
rescue DiagonalError
  puts "%#{PROGNAME}-E-DIAGONAL, error in RowMatrix calculation"
else
  ToneRow.report( rm.rowmatrix, rm.prime, rm.retrograde,
                  rm.inverse, rm.invretro, options )
end
