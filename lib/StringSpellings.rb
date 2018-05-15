#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# StringSpellings.rb
#
# Copyright © 2011-2018 Lorin Ricker <Lorin@RickerNet.us>
# Version 3.0, 05/15/2018
#

class String

  # Return either "an" if word begins with a vowel, return "a" otherwise
  def article( fullphrase = false )
    article = self[0] =~ /[aeiou]/i ? "an" : "a"
    article += " " + self if fullphrase
    return article
  end  # article

  # Return the proper plural form of word (note: plurals in English are rife
  # with exceptions, so the following is likely incomplete and imperfect, so
  # use "irregular" to handle unencoded exceptions) --
  def pluralize( howmany = 2, irregular = nil)
    # Assert: Invoking object is a single-word string; argument howmany is
    #         typically an integer variable to distinguish "one" from "many";
    #         irregular is a mutating plural form (if such is not found in
    #         the iwords hash herein), e.g., "geese" instead of "gooses".
    return ( howmany != 1 ? irregular : word ) if irregular

    word = self.to_s
    wsym = self.to_sym
    # Mutated (irregular) forms:
    iwords = Hash.new
    iwords = { # exceptions to "...o" -> "...oes" here:
               piano: "pianos", zero: "zeros", pro: "pros", quarto: "quartos",
               photo: "photos", volcano: "volcanos", kimono: "kimonos",
               # other irregulars:
               person: "people", child: "children", woman: "women", man: "men",
               datum: "data", data: "data", index: "indices", matrix: "matrices",
               medium: "media", phenomenon: "phenomena", formula: "formulae",
               maximum: "maxima", minimum: "minima",
               nucleus: "nuclei", syllabus: "syllabi", nebula: "nebulae",
               basis: "bases", crisis: "crises", thesis: "theses",
               appendix: "appendices", focus: "foci", criterion: "criteria",
               life: "lives", fungus: "fungi", cactus: "cacti",
               mouse: "mice", goose: "geese", moose: "moose", deer: "deer",
               calf: "calves", leaf: "leaves", knife: "knives",
               foot: "feet", barracks: "barracks" }
    return iwords[wsym] if iwords[wsym]

    # "cherry" -> "cherries", "lady" -> "ladies",
    # but "day" -> "days" and "...key" -> "...keys"
    if ( word[-1] == "y" )      &&      # ends in "y",
       ( word[-2] =~ /[^aeiou]/ )       # and is not preceeded by a vowel
      return howmany != 1 ? word[0..-2] + "ies" : word
    end  # if ...

    # "kiss" -> "kisses", "box" -> "boxes", "potato" -> "potatoes",
    # "dish" -> "dishes", "witch" -> "witches",
    # but all other "word" -> "words"...
    s = ( word[-1]   == "s"  ||
          word[-1]   == "x"  ||
          word[-1]   == "o"  ||
          word[-2,2] == "sh" ||
          word[-2,2] == "ch"   ) ? "es" : "s"
    return howmany != 1 ? word + s : word
  end  # pluralize

end  # class String
