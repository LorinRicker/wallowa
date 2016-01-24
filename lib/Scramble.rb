#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Scramble.rb
#
# Copyright © 2014-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.1, 11/11/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'pp'

# Dependency: Uses Ruby *Random* standard library module (available since v2.x).
#
# Provides the means to shuffle, scramble or thoroughly mix-up a collection of
# arbitrary objects, and to randomly retrieve (e.g., "deal") a subset of one or
# more of those objects.
#
# The physical analogy is to "shuffle a deck of playing cards" and then to
# "deal" the cards one-at-a-time, or to "shake up a bag of marbles" and then
# to choose the marbles one-at-a-time.
#
# Relies on three instance variables:
#   @vals : An array which holds the 'raw' objects (in the order stored)
#   @pile : A hash which collects the objects, associating each stored object
#           (the Value) with a random number (its Key)
#   @deck : An array which receives a sorted version of the +@pile+ hash, thus
#           presenting its elements as a sorted list of [rand#,object] pairs
#           retrieval of these array elements "in sorted order" is now equi-
#           valent to "dealing them in random order".
#
# Because, as each Value object is +@pile+-stored, it is associated with a unique
# (and potentially different for each run) random number, and then the +@pile+ is
# sorted into the +@deck+, that sort serves as a kind of "reverse-shuffle" so
# that as Values are retrieved by sorted (random) Key from the +@deck-array+,
# they are retrieved in random order, distinct from the order in which they
# were stored.
#
# Instance variables:
#
#    @vals       : An array which holds the 'current' values (for reshuffles).
#    @pile       : A hash which collects the (unrandomized) collection objects.
#    @deck       : An array which is the randomized collection.
#    @deckindex  : Initially nil to indicate that objects are being collected
#                  into the +@pile+ and that @deck has not yet been "randomized"
#                  (sorted).  The +shuffle+ method sets +@deckindex+ to 0 (zero),
#                  and +@deckindex+ is incremented by 1 (one) for each object
#                  which is dealt (by the fetch method). The (private) method
#                  +reset_deck+ sets +@deckindex+ back to nil, indicating that the
#                  +@pile+ and the +@deck+ are again being collected.
#    @seed       : An integer which, if provided as the *optional* parameter to
#                  Scramble.new, provides a known seed value to Random, thus
#                  producing a repeatable random sequence (useful for testing
#                  and verification).
#    @randgen    : An instance of Random for this instance of Scramble.  If a
#                  fixed seed is not provided to Scramble.new, then each instance
#                  of Scramble runs with a unique (pseudo)Random number sequence;
#                  a specific, shared seed value puts each instance on the same
#                  (pseudo)Random sequence/cycle.
#
# For convenience, +@pile+, +@deck+, +@vals+, +@deckindex+ and +@seed+ are exposed
# as read-only attributes of the class.

class Scramble

  class EndOfCollection < StandardError; end
  class NotYetDone      < StandardError; end

  attr_reader :vals, :pile, :deck
  attr_reader :deckindex, :seed

  # Responds to <tt>obj = Scramble.new( seed )</tt>.
  def initialize( seed = nil )
    reset_rand( seed )
    self.reset
    @factorial_series = [ 1 ]
  end  # initialize

# =====

  # Calculates n! (n-factorial), using a memoized (@factorial_series) algorithm.
  def factorial( n )
    @factorial_series[n] ||= n * factorial( n-1 )
  end  # factorial
  # +n!+ is an alias for this class's +factorial+ method.
  alias :n! :factorial

  # Calculates the number of combination of "'n' things taken 'k' at a time",
  # or the number of k-combinations a set S of n elements.  Wikipedia gives
  # this calculation as: n!/k!(n-k)!
  # (see http://en.wikipedia.org/wiki/Combination)
  def combination( n, k )
    return 0 if k > n
    n!(n) / ( n!(k) * n!(n-k) )
  end  # combination

  # Reports the k-combinations of @vals.size elements taken k at a time.
  def to_combination( k )
    k = k.to_i if not k.kind_of? Integer
    combination( @vals.size, k )
  end  # to_combination

  def report_combination( k )
    combos = to_combination( k ).thousands
    return "Possible #{combos} combinations of #{@deck.size} elements taken #{k} at a time."
  end  # report_combination

# =====

  # Resets (starts over) with a new collection of +@vals+.
  #
  # +@deckindex+ is (re)set to nil indicating that the +@deck+ is empty (new)
  # and unsorted.
  #
  # Calling (client) environment must now (re)+store+ objects into the +@pile+;
  # when the last object has been stored in the +@pile+, the calling environment
  # must invoke +shuffle+ to "randomize" (sort) the +@pile+ into the +@deck+.
  def reset
    @vals = []
    reset_deck
  end  # reset

  # Stashes (stores) the parameter object in the +@vals+ array.
  #
  # Ensures that +@deckindex+ remains nil until +shuffle+ is invoked to
  # "randomize" (sort) +@pile+ into the +@deck+, at which point calling
  # environment can invoke +deal+ and/or +fetch+ to retrieve +@deck+ objects.
  def store( obj )
    @vals << obj
    #@pile[ @randgen.rand ] = obj
    @deckindex = nil if not @deckindex
    return @vals.size
  end  # store

  # Stashes (stores) each element of +@vals+ into the +@pile+ hash, assigning
  # it a random key, and then sorts +@pile+ into +@deck+.  The result is a
  # "randomized sequence" when retrieved sequentially from +@deck+.
  def shuffle
    @pile = Hash.new
    @vals.each { |v| @pile[ @randgen.rand ] = v }
    @deck = @pile.sort
    @deckindex = 0   # ready to deal...
    return @deck.size
  end  # shuffle

  # Returns "the next" object to caller from +@deck+, keeping internal track of
  # "next object" via +@deckindex+, or returns nil when the last legitimate
  # value has previously been produced and resets internal state to "start over
  # again" (i.e., recycles the sequence of values).
  #
  # +fetch+ takes a single optional parameter, +valueonly+, which defaults to true
  # to control the return of the object's value (only).  If +valueonly+ is false,
  # then the return value is a +[key,value]+ pair (an array); this is primarily
  # useful for debugging and verification, as in normal use, only the values in
  # randomized order of return are desired.
  #
  # Both +fetch+ and +deal+ require that the calling environment has stored one
  # or more objects via +store+, and when all desired objects have been stored
  # in the +@pile+, the caller has invoked +shuffle+ to "randomize" (sort)
  # the +@pile+ into the +@deck+.  Any attempt to +fetch+ *after* +reset+ and
  # *before* +shuffle+ have been called results in raising the +NotYetDone+
  # exception.
  def fetch( valueonly = true )
    if @deckindex
      if @deckindex < @deck.length
        val = valueonly ? @deck[@deckindex][1] : @deck[@deckindex]
        @deckindex += 1
        return val
      else
        @deckindex = 0  # recycle again...
        return nil
      end
    else
      raise NotYetDone, "Scramble collection still in progress"
    end
  end  # fetch

  # Collects and returns a collection ("deals a hand") of +elements+ objects
  # from the randomized +@deck+.  Each collection (or "hand") is an array.
  #
  # If <b>@deck mod elements != 0</b>, the last "hand" will be padded with nil
  # values to make a final collection of +nobj+ values.
  #
  # Both +deal+ and +fetch+ require that the calling environment has stored one
  # or more objects via +store+, and when all desired objects have been stored
  # in the +@pile+, the caller has invoked +shuffle+ to "randomize" (sort)
  # the +@pile+ into the +@deck+.  Any attempt to +fetch+ *after* +reset+ and
  # *before* +shuffle+ have been called results in raising the +NoteYetDone+
  # exception.
 def deal( elements = 1, valueonly = true )
    elements = elements.to_i if not elements.kind_of? Integer
    hand = []
    exhausted = false
    until ( hand.length >= elements ) || exhausted
      val = self.fetch( valueonly )
      exhausted = (val == nil)
      hand << val if not exhausted
    end
    hand << nil while hand.length < elements
    return hand, exhausted
  end  # deal

  # Reports the class's instance variables in pretty-print format.
  def to_s
    puts "size of @vals = #{@vals ? @vals.size : 0 }"
    pp @vals
    puts "size of @pile = #{@pile ? @pile.size : 0 }"
    pp @pile
    puts "size of @deck = #{@deck ? @deck.size : 0 }"
    pp @deck
    puts "    @deckindex: '#{@deckindex ? @deckindex : 'nil'}'"
    puts "         @seed: '#{@seed}'"
  end  # to_s

  private  # =======================
  def reset_deck
    @deck = []
    @deckindex = nil
  end  # reset_deck

  def reset_rand( seed )
    @seed = seed || Random.new_seed
    @randgen = Random.new( @seed )
  end  # reset_rand

end  # class

# ---
# === Testing / Demo ===
# use:
#     $ ruby lib/Scramble.rb
#
if $0 == __FILE__
  require_relative 'StringEnhancements'

  carddeck = Scramble.new
  cards    = %w[ 2 3 4 5 6 7 8 9 10 J Q K A ]
  cards.each { |c| carddeck.store( "#{c}♠")}
  cards.each { |c| carddeck.store( "#{c}♣")}
  cards.each { |c| carddeck.store( "#{c}♥")}
  cards.each { |c| carddeck.store( "#{c}♦")}

  carddeck.shuffle
  carddeck.to_s
  tsiz = carddeck.deck.size
  h = 6  # hands
  n = 5  # cards in a hand
  puts "\nDeal #{h} poker hands (deck of #{tsiz} cards):"
  (1..h).each { |t| puts "  #{carddeck.deal(n)}" }
  puts carddeck.report_combination( n )
  puts "(This value is verified in http://en.wikipedia.org/wiki/Combination,"
  puts " 'Example of counting combination': 2,598,960)"

  carddeck.shuffle
  h =  4  # hands
  n = 13  # cards in a hand
  puts "\nDeal #{h} bridge hands (deck of #{tsiz} cards):"
  (1..h).each { |t| puts "  #{carddeck.deal(n)}" }
  puts carddeck.report_combination( n )
end
