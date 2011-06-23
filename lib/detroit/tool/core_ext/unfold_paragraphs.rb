# TODO: Replace with facets/string/unfold

class String

  #
  def unfold_paragraphs
    blank = false
    text  = ''
    split(/\n/).each do |line|
      if /\S/ !~ line
        text << "\n\n"
        blank = true
      else
        if /^(\s+|[*])/ =~ line
          text << (line.rstrip + "\n")
        else
          text << (line.rstrip + " ")
        end
        blank = false
      end
    end
    text = text.gsub("\n\n\n","\n\n")
    return text
  end

end

