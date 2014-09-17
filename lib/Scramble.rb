#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Scramble.rb
#
# Copyright © 2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 09/15/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

require 'pp'

# Dependency: Uses Ruby *Random* standard library module (available since v2.x).
#
# Provides the means to shuffle, scramble or thoroughly mix-up a collection of
# arbitrary objects, to randomly retrieve (e.g., "deal") a collection which is
# read in a predictable order.  The physical analogy is to "shuffle a deck of
# playing cards" and then to "deal" the cards one-at-a-time, or to "shake up a
# bag of marbles" and then to choose the marbles one-at-a-time.
#
# Relies on two instance variables:
#   @pile : A hash which collects the objects, associating each stored object
#           (the Value) with a random number (its Key)
#   @deck : An array which receives a sorted version of the @pile hash, thus
#           presenting its elements as a sorted list of [rand#,object] pairs
#
# Because, as each Value object is @pile-stored, it is associated with a unique
# (and potentially different for each run) random number, and then the @pile is
# sorted into the @deck, that sort serves as a kind of "reverse-shuffle" so
# that as Values are retrieved by sorted (random) Key from the @deck-array,
# they are retrieved in random order, distinct from the order in which they
# were stored.
#
# Instance variables:
#
#    @pile       : A hash which collects the (unrandomized) collection objects
#    @deck       : An array which is the randomized collection
#    @deckindex  : Initially nil to indicate that objects are being collected
#                  into the @pile and that @deck has not yet been "randomized"
#                  (sorted)
#    @seed       : An integer which, if provided as the *optional* parameter to
#                  Scramble.new, provides a known seed value to Random, thus
#                  producing a repeatable random sequence (useful for testing
#                  and verification).
#    @randgen    : An instance of Random for this instance of Scramble.  If a
#                  fixed seed is not provided to Scramble.new, then each instance
#                  of Scramble runs with a unique (pseudo)Random number sequence;
#                  a specific, shared seed value puts each instance on the same
#                  (pseudo)Random sequence.
#    @collisions : An internal bookkeeping counter, just to see if random numbers
#                  reoccur which would cause hash table (key) collisions.  Reported
#                  only by to_s, and just for information.
#
# For convenience, +@pile+, +@deck+, +@deckindex+, +@seed+ and +@collisions+ are
# exposed as read-only attributes of the class.

class Scramble

  class EndOfCollection < StandardError; end
  class NotYetDone      < StandardError; end

  attr_reader :pile, :deck
  attr_reader :deckindex, :seed, :collisions

  # Responds to <tt>obj = Scramble.new( seed )</tt>.
  def initialize( seed = nil )
    @collisions = 0
    @pile = Hash.new
    self.reset
    self.reset_rand( seed )
  end  # initialize

  # Resets (starts over) with a new +@deck+.  +@deckindex+ is (re)set to +nil+
  # indicating that the +@deck+ is empty (new) and unsorted. Calling (client)
  # environment must now (re)+store+ objects into the +@pile+; when the last
  # object has been stored in the +@pile+, the calling environment must invoke
  # +store_done+ to "randomize" (sort) the +@pile+ into the +@deck+.
  def reset
    @deck = Array.new
    @deckindex = 0
  end  # reset

  # Stashes (stores) the parameter object in the +@pile+ hash, assigning
  # it a random key, such that when +@pile+ is later sorted into +@deck+,
  # the result is a "randomized sequence" when retrieved sequentially from
  # that +@deck+ array.  Ensures that +@deckindex+ remains +nil+ until
  # +store_done+ is invoked to "randomize" (sort) +@pile+ into the +@deck+,
  # at which point calling environment can invoke +deal+ and/or +fetch+ to
  # retrieve +@deck+ objects.
  def store( obj )
    until ! @pile[ rno = @randgen.rand ]
      @collisions += 1
    end
    @pile[rno] = obj
    @deckindex = nil
  end  # store

  # Prepares a new +@deck+, (re)sets +@deckindex+ from +nil+ (falsity) to +0+,
  # ready to fetch first object from +@deck+, and assigns the "randomized" (sorted)
  # +@pile+ to +@deck+.
  def store_done
    self.reset
    @deck = @pile.sort
  end  # store_done

  # Returns "the next" object to caller from +@deck+, keeping internal track of
  # "next object" via +@deckindex+, or returns +nil+ when the last legitimate
  # value has previously been produced and resets internal state to "start over
  # again" (i.e., recycles the sequence of values).
  #
  # +fetch+ takes a single optional parameter, +valueonly+, which defaults to +true+
  # to control the return of the object's value (only).  If +valueonly+ is +false+,
  # then the return value is a +[key,value]+ pair (an array); this is primarily
  # useful for debugging and verification, as in normal use, only the values in
  # randomized order of return are desired.
  #
  # Both +fetch+ and +deal+ require that the calling environment has stored one
  # or more objects via +store+, and when all desired objects have been stored
  # in the +@pile+, the caller has invoked +store_done+ to "randomize" (sort)
  # the +@pile+ into the +@deck+.  Any attempt to +fetch+ *after* +reset+ and
  # *before* +store_done+ have been called results in raising the +NoteYetDone+
  # exception.
  def fetch( valueonly = true )
    if @deckindex
      @deckindex += 1
      if @deckindex < @deck.length
        valueonly ? @deck[@deckindex][1] : @deck[@deckindex]
      else
        self.reset
        return nil
      end
    else
      raise NotYetDone, "Scramble collection still in progress"
    end
  end  # fetch

  # Collects and returns a collection ("deals a hand") of +numobj+ objects
  # from the randomized +@deck+.  Each collection (or "hand") is an array.
  #
  # If <b>@deck % numobj != 0</b>, the last "hand" will be padded with nil
  # values to make a final collection of +nobj+ values.
  #
  # Both +deal+ and +fetch+ require that the calling environment has stored one
  # or more objects via +store+, and when all desired objects have been stored
  # in the +@pile+, the caller has invoked +store_done+ to "randomize" (sort)
  # the +@pile+ into the +@deck+.  Any attempt to +fetch+ *after* +reset+ and
  # *before* +store_done+ have been called results in raising the +NoteYetDone+
  # exception.
 def deal( numobj )
    hand = []
    exhausted = false
    until hand.length >= numobj || exhausted
      val = self.fetch
      exhausted = (val == nil)
      hand << val if !exhausted
    end
    hand << nil while hand.length < numobj
    return hand
  end  # deal

  # Custom <b>to string</b> dumps the class's instance variables
  # in pretty-print format.
  def to_s
    puts "size of @pile = #{@pile.length}"
    pp @pile
    puts "size of @deck = #{@deck.length}"
    pp @deck
    puts "     @deckindex: '#{@deckindex}'"
    puts "          @seed: '#{@seed}'"
    puts "    @collisions: '#{@collisions}'"
  end  # to_s

  private
  def reset_rand( seed )
    @seed = seed || Random.new_seed
    @randgen = Random.new( @seed )
  end  # reset_rand

end  # class
