#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# FileFilters.rb
#
# Copyright © 2012-2016 Lorin Ricker <Lorin@RickerNet.us>
# Version 0.2, 06/18/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Classes Expression, All, Or, And, Not, FileName, Larger, and
# Writable are adapted from Russ Olsen's "Design Patterns in Ruby"
# (Addison Wesley, Boston, 2008, ISBN 978-0-321-49045-2), Chapter 15,
# "Assembling Your System with the Interpreter", pp. 263ff.
# Classes Smaller, Before and Since are extensions of these...
#
# The difference here is that, instead of taking a directory-spec
# as the argument to each Class's evaluate routine (see above pages),
# these each take an array "dirray" containing zero or more filespecs,
# much like a command-line glob would generate into the ARG[] array.

# require 'find'
require 'date'
require 'time'

class Expression
  def |( other )
    Or.new( self, other )
  end # |

  def &( other )
    And.new( self, other)
  end  # &

  def all
    All.new
  end  # all

  def except( expr )
    Not.new( expr )
  end  # except

  def larger( sz )
    Larger.new( sz )
  end  # larger

  def smaller( sz )
    Smaller.new( sz )
  end  # larger

  def name( pat )
    FileName.new( pat )
  end  # name

  def writable
    Writable.new
  end  # writable

  def before( dt )
    Before.new( dt )
  end  # before

  def since( dt )
    Since.new( dt )
  end  # since
end  # class Expression

class All < Expression
  def evaluate( dirray )
    dirray
  end  # evaluate
end  # class All

class Not < Expression
  def initialize( expr )
    @expression = expr
  end  # initialize

  def evaluate( dirray )
    # Remove all filespecs returned by the expression,
    # resulting in all files not returned by that expression
    dirray - @expression.evaluate( dirray )
  end  # evaluate
end  # class Not

class Or < Expression
  def initialize( expr1, expr2 )
    @expression1 = expr1
    @expression2 = expr2
  end  # initialize

  def evaluate( dirray )
    result1 = @expression1.evaluate( dirray )
    result2 = @expression2.evaluate( dirray )
    ( result1 + result2 ).sort.uniq
  end  # evaluate
end  # class Or

class And < Expression
  def initialize( expr1, expr2 )
    @expression1 = expr1
    @expression2 = expr2
  end  # initialize

  def evaluate( dirray )
    result1 = @expression1.evaluate( dirray )
    result2 = @expression2.evaluate( dirray )
    ( result1 & result2 )
  end  # evaluate
end  # class And

class FileName < Expression
  def initialize( pat )
    @pattern = pat
  end  # initialize

  def evaluate( dirray )
    results = []
    dirray.each do | p |
      results << p if File.fnmatch( @pattern, File.basename(p) )
    end
    results
  end  # evaluate
end  # class FileName

class Larger < Expression
  def initialize( sz )
    @size = sz
  end  # initialize

  def evaluate( dirray )
    results = []
    dirray.each do | p |
      results << p if File.size(p) >= @size
    end
    results
  end  # evaluate
end  # class Larger

class Smaller < Expression
  def initialize( sz )
    @size = sz
  end  # initialize

  def evaluate( dirray )
    results = []
    dirray.each do | p |
      results << p if File.size(p) <= @size
    end
    results
  end  # evaluate
end  # class Smaller

class Writable < Expression
  def evaluate( dirray )
    results = []
    dirray.each do | p |
      results << p if File.writeable?(p)
    end
    results
  end  # evaluate
end  # class Writable

class Before < Expression
  def initialize( dt )
    @date = Time.parse( dt )
  end  # initialize

  def evaluate( dirray )
    results = []
    dirray.each do | p |
      results << p if File.mtime(p) <= @date
    end
    results
  end  # evaluate
end  # class Before

class Since < Expression
  def initialize( dt )
    @date = Time.parse( dt )
  end  # initialize

  def evaluate( dirray )
    results = []
    dirray.each do | p |
      results << p if File.mtime(p) >= @date
    end
    results
  end  # evaluate
end  # class Since
