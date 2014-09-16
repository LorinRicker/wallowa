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

class Scramble

# Provides the means to shuffle, scramble or thoroughly mix-up a collection of
# arbitrary objects, to randomly retrieve (e.g., "deal") a collection which is
# read in a predictable order.  The physical analogy is to "shuffle a deck of
# playing cards" and then to "deal" the cards one-at-a-time, or to "shake up a
# bag of marbles" and then to choose the marbles one-at-a-time.
#
# Relies on two instance variables:
#    @bag : A Hash which collects the objects, associating each stored
#           object (the Value) with a random number (its Key)
#   @sack : An Array which receives a sorted version of the @bag hash,
#           thus presenting its elements as a sorted list of [rand,obj]
#           pairs
#
# Because, as each Value object is @bag-stored, it is associated with a unique
# (and potentially different for each run) random number, and then the @bag is
# sorted into the @sack, that sort serves as a kind of "reverse-shuffle" so
# that as Values are retrieved by sorted (random) Key from the @sack-array,
# they are retrieved in random order, distinct from the order in which they
# were stored.

  def initialize( seed = nil )
    @bag  = Hash.new
    @sack = Array.new
    self.reset
    @seed = seed || Random.new_seed
    self.reset_rand
    @randgen = Random.new( @seed )
    @collisions = 0
    @store_done = false
  end  # initialize

  def reset_rand
    Kernel.srand( @seed ) if @seed
  end  # reset_rand

  def reset
    @sackindex = 0
  end  # reset

  def store( obj )
    until ! @bag[ rno = @randgen.rand ]
      @collisions += 1
    end
    @bag[rno] = obj
    @store_done = false
  end  # store

  def store_done
    @store_done = true
    @sack = @bag.sort
  end  # store_done

  def fetch( value = true )
    if @store_done
      @sackindex += 1
      self.reset if @sackindex > @sack.length - 1
      value ? @sack[@sackindex][1] : @sack[@sackindex]
    else
      raise "Bag storage still in progress"
    end
  end  # fetch

  def deal( nobj )
    # xxx
  end  # deal

  def to_s
    puts "size of @bag = #{@bag.length}"
    pp @bag
    puts "size of @sack = #{@sack.length}"
    pp @sack
    puts "      @seed: '#{@seed}'"
    puts " @sackindex: '#{@sackindex}'"
    puts "@collisions: '#{@collisions}'"
    puts "@store_done: '#{@store_done}'"
  end  # to_s

end  # class
