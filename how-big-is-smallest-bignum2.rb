# A way to determine the "boundary" between the largest Fixnum and the smallest Bignum

start = Time.now
largest_known_fixnum = 1
smallest_known_bignum = nil

until smallest_known_bignum == largest_known_fixnum + 1
  if smallest_known_bignum.nil?
    next_number_to_try = largest_known_fixnum * 1000
  else
    next_number_to_try = (smallest_known_bignum + largest_known_fixnum) / 2
    # Geometric mean would be more efficient, but more risky
  end

  if next_number_to_try <= largest_known_fixnum ||
       smallest_known_bignum && next_number_to_try >= smallest_known_bignum
    raise "Can't happen case"
  end

  case next_number_to_try
    when Bignum then smallest_known_bignum = next_number_to_try
    when Fixnum then largest_known_fixnum = next_number_to_try
    else raise "Can't happen case"
  end
end

finish = Time.now
puts "The largest fixnum is #{largest_known_fixnum}"
puts "The smallest bignum is #{smallest_known_bignum}"
puts "Calculation took #{finish - start} seconds"
