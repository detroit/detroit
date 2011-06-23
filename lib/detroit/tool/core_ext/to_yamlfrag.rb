class Object

  #
  def to_yamlfrag
    to_yaml.sub("---",'').rstrip
  end

end

