  #!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Combinatorics.rb
#
# Copyright © 2014-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.2, 07/11/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

class Combinatorics

  # Initialize these two series as $global variables:
  $Factorial_Series = [ 1 ]     # This first term represents 0!
  $Fibonacci_Series = [ 0, 1 ]  # The canonical first two terms of Fibonacci

public
  # Calculates the first "n" Fibonacci terms, using a memoized ($Fibonacci_Series)
  # algorithm.
  def self.fibonacci( n )
    $Fibonacci_Series[n] ||= fibonacci( n-2 ) + fibonacci( n-1 )
  end  # fibonacci
  def self.fib( n )
    fibonacci( n )
  end # fib

  # Calculates n! (n-factorial), using a memoized ($Factorial_Series) algorithm.
  # Combinatorics are often defined in terms of factorials, so this function is
  # included here.
  def self.factorial( n )
    $Factorial_Series[n] ||= n * factorial( n-1 )
  end  # factorial
  def self.n!( n )
    factorial( n )
  end  # n!

  # Calculates the number of permutations of "'n' things taken 'k' at a time",
  # the number of unique orderings, or k-permutations, of a set S of n elements.
  # Wikipedia gives this calculation as: n!/(n-k)!
  # Note that the number of permutations of a set of n elements is exactly n!,
  # which is the n-permutation of that set (with k = n), which is n!/(n-n)!
  # = n!/0! = n!/1 = n!.
  # (see http://en.wikipedia.org/wiki/Permutation)
  def self.k_permutations( n, k )
    return 0 if k > n
    n!(n) / ( n!(n-k) )
  end  # k_permutations

  # Calculates the number of permutations of "'n' things taken n at a time",
  # the number of unique orderings, or n-permutation, of a set S of n elements.
  # Wikipedia gives this calculation as: n!
  # Note that the number of permutations of a set of n elements is exactly n!,
  # which is the n-permutation of that set (with k = n), which is n!/(n-n)!
  # = n!/0! = n!/1 = n!.
  # (see http://en.wikipedia.org/wiki/Permutation)
  def self.permutations( n )
    k_permutations( n, n )  # or n!
  end  # permutations

  # Calculates the number of combinations of "'n' things taken 'k' at a time",
  # or the number of k-combinations a set S of n elements.  Wikipedia gives
  # this calculation as: n!/k!(n-k)!
  # Note that the number of combinations of a set of n elements is exactly 1,
  # which is the n-combination of that set (with k = n), which is n!/n!(n-n)!
  # = n!/n!*0! = n!/n!*1 = n!/n! = 1.
  # (see http://en.wikipedia.org/wiki/Combination)
  def self.combinations( n, k )
    return 0 if k > n
    n!(n) / ( n!(k) * n!(n-k) )
  end  # combinations

end  # class Combinatorics
