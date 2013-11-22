class String

  # Find actual filename (casefolding) and returns it.
  # Returns nil if no file is found.

  def to_actual_filename
    Dir.glob(self, File::FNM_CASEFOLD).first
  end

  # Find actual filename (casefolding) and replace string with it.
  # If file not found, string remains the same and method returns nil.

  def to_actual_filename!
    filename = to_actual_filename
    replace(filename) if filename
  end

end

