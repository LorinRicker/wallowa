  #!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Combinatorics.rb
#
# Copyright © 2014-2017 Lorin Ricker <Lorin@RickerNet.us>
# Version 2.0, 07/09/2017
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

module Combinatorics

### Intended to be used as a MIX-IN (via Ruby include) --

  # Initialize the series as $global variables:
  $Factorial_Series = [ 1 ]     # This first term represents 0!
  $Fibonacci_Series = [ 0, 1 ]  # The canonical first two terms of Fibonacci

  # Calculates the first "n" Fibonacci terms, using a memoized ($Fibonacci_Series)
  # algorithm.
  def fibonacci( n )
    $Fibonacci_Series[n] ||= fibonacci( n-2 ) + fibonacci( n-1 )
  end  # fibonacci
  alias :fib :fibonacci

  # Calculates n! (n-factorial), using a memoized ($Factorial_Series) algorithm.
  # Combinatorics are often defined in terms of factorials, so this function is
  # included here.
  def factorial( n )
    $Factorial_Series[n] ||= n * factorial( n-1 )
  end  # factorial
  # +n!+ is an alias for this class's +factorial+ method.
  alias :n! :factorial

  # Calculates the number of permutations of "'n' things taken 'k' at a time",
  # the number of unique orderings, or k-permutations, of a set S of n elements.
  # Wikipedia gives this calculation as: n!/(n-k)!
  # Note that the number of permutations of a set of n elements is exactly n!,
  # which is the n-permutation of that set (with k = n), which is n!/(n-n)!
  # = n!/0! = n!/1 = n!.
  # (see http://en.wikipedia.org/wiki/Permutation)
  def k_permutation( n, k )
    return 0 if k > n
    n!(n) / ( n!(n-k) )
  end  # k_permutation

  # Calculates the number of permutations of "'n' things taken n at a time",
  # the number of unique orderings, or n-permutation, of a set S of n elements.
  # Wikipedia gives this calculation as: n!
  # Note that the number of permutations of a set of n elements is exactly n!,
  # which is the n-permutation of that set (with k = n), which is n!/(n-n)!
  # = n!/0! = n!/1 = n!.
  # (see http://en.wikipedia.org/wiki/Permutation)
  def permutation( n )
    k_permutation( n, n )  # or n!
  end  # permutation

  # Calculates the number of combinations of "'n' things taken 'k' at a time",
  # or the number of k-combinations a set S of n elements.  Wikipedia gives
  # this calculation as: n!/k!(n-k)!
  # Note that the number of combinations of a set of n elements is exactly 1,
  # which is the n-combination of that set (with k = n), which is n!/n!(n-n)!
  # = n!/n!*0! = n!/n!*1 = n!/n! = 1.
  # (see http://en.wikipedia.org/wiki/Combination)
  def combination( n, k )
    return 0 if k > n
    n!(n) / ( n!(k) * n!(n-k) )
  end  # combination

  # Reports the k-combinations of @vals.size elements taken k at a time.
  def to_combinations( k )
    k = k.to_i if not k.kind_of? Integer
    combinations( @vals.size, k )
  end  # to_combinations

  def report_combinations( k )
    combos = to_combinations( k ).thousands
    return "Possible #{combos} combinations of #{@deck.size} elements taken #{k} at a time."
  end  # report_combinations

end  # module
