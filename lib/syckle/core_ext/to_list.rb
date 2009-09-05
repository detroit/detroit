class Array

  def to_list
    self
  end

end

class NilClass

  def to_list
    []
  end

end

class String

  # Helper method for cleaning list options.
  # This will split the option on ':' or ';'
  # if it is a string, rather than an array.
  # And it will make sure there are no nil elements.

  def to_list
    split(/[:;,\n]/)
  end

end

