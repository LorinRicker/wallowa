#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# how-many-chords-on-piano.rb
#
# Copyright (C) 2012-2014 Lorin Ricker <lorin@rickernet.us>
# Version: 1.0, 11/21/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# How many chords (simultaneously depressed key combinations) are
# theoretically possible on a modern piano keyboard, 88 keys?
#
# Note that answering this question, and questions related to it,
# requires the computation of Combinations, not Permutations; in
# other words, we're not worrying about the order of notes (i.e.,
# melodies), only the unordered combinations of them (vertical
# structures), and thus counting those combinations.
# See en.wikipedia.org/wiki/Combination and .../wiki/Permutation.
#
# The total number of all possible chords is equal to the sum of
# the number of single-note "chords" (trivially, 88), plus
# the number of two-note chords, plus the number of three-note
# chords, ...and so on..., up to the number of eighty-eight-note
# chords (again, a trivial number, 1).  In the abstract, one could
# even count the number of zero-note chords (trivially, 1), just
# for full symmetry on the analysis.
#
# Thus:
#
#  totalChords = C(88,0) + C(88,1) + C(88,2) + C(88,3) + ... + C(88,88)
#
# where:
#
#  C(n,k) = (n(n-1)...(n-k+1))/(k(k-1)...1)
#         = n!/(k!(n-k)!)        [see en.wikipedia.org/wiki/Combination]
#
# Given that
#    88! = 185,482,642,257,398,439,114,796,845,645,546,284,380,220,968,
#          949,399,346,684,421,580,986,889,562,184,028,199,319,100,141,
#          244,804,501,828,416,633,516,851,200,000,000,000,000,000,000
# exactly (yikes!), or approximately 1.85e135, well, it looks like we
# will be working with some very huge numbers.  Fortunately, Ruby's
# Bignum class handles such numbers and calculations with impunity.
#
# Note that the formula for combinations holds for the trivial cases:
#
#   C(88,0)  = 88!/(0!(88-0)!)   = 88!/88! =  1 (by definition, 0! is 1)
#   C(88,1)  = 88!/(1!(88-1)!)   = 88!/87! = 88
#   ...
#   C(88,87) = 88!/(87!(88-87)!) = 88!/87! = 88
#   C(88,88) = 88!/(88!(88-88)!) = 88!/88! =  1
#
# As calculations such as "What is the theoretical total number of
# chords playable on an 88-key piano?" and derivatives, such as
# "What are the total number of chords of 10 notes or less which are
# playable by human hands?", all require multiple calculations of
# factorials, especially 88!, we will use a version of "factorial"
# which is memoized: factorial_fast(), aliased as n!().
# See 'factorial.rb'.
#

require 'pp'
require_relative 'factorial'
require_relative 'lib/StringEnhancements'

  PIANO_KEYS  = 88
  FACTORIAL88 = n!(PIANO_KEYS)  # value used many times, also doing this
                                # calculation initializes the memoized
                                # array-variable @factorial_series,
                                # which now holds [0!,1!,2!,3!,...88!].
                                # All subsequent "calculations" of any
                                # n! are now simply array-lookups.

  def chordCombos( nk )
    FACTORIAL88 / ( n!(nk) * n!(PIANO_KEYS - nk) )
  end  # chordCombos

  def numKeyChords( cbk, nk )
    totchords = 0
    cbk.each { |k,tc| totchords += tc if k <= nk }
    return totchords
  end  # numKeyChords

  def how_many( title, chords )
    puts "\n#{title}",
      "#{chords.thousands} (or #{sprintf("%6.2e",chords)}), which is",
      "#{chords.numbernames} chords."
  end  # how_many

# ==========
chordsByKeys = Hash.new  # chordCombos by #-of-keys

# Calculate hash of #-of-chords for each #-of-keys:
(PIANO_KEYS+1).times { |p| chordsByKeys[p] = chordCombos(p) }

if ARGV[0]  # any non-nil argument will dump...
  puts "\n88! = #{FACTORIAL88.thousands} (or #{sprintf("%6.2e",FACTORIAL88)})\n\n"
  puts "#{FACTORIAL88.numbernames}\n\n"
  pp chordsByKeys
end

# Total up the grand-total number of possible chords:
totalChords = numKeyChords( chordsByKeys, PIANO_KEYS )

# Total up the number of possible chords playable by
# ten fingers on two human hands:
tenKeyChords = numKeyChords( chordsByKeys, 10 )

# Total up the number of possible chords playable by
# five fingers on one human hand (e.g., "for the left-hand alone"):
fiveKeyChords = numKeyChords( chordsByKeys, 5 )

# Total up the number of possible chords playable by
# twenty fingers on four human hands (either one or two pianos):
twentyKeyChords = numKeyChords( chordsByKeys, 20 )

how_many( "Grand total number of possible chords on an #{PIANO_KEYS}-key piano:",
          totalChords )

how_many( "Number of possible chords playable by two hands (ten fingers):",
          tenKeyChords )

how_many( "Number of possible chords playable by one hand (five fingers):",
          fiveKeyChords )

how_many( "Number of possible chords playable by four hands (twenty fingers):",
          twentyKeyChords )
