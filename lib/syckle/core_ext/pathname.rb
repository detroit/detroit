require 'facets/pathname'

class Pathname

  # Like directory? but return self if true, otherwise nil.
  def dir?
    directory? ? self : nil
  end

  def mkdir_p
    FileUtils.mkdir_p(to_s)
  end

# Already in Facets
#
#    def glob(*opts)
#      flags = 0
#      opts.each do |opt|
#        case opt when Symbol, String
#          flags += File.const_get("FNM_#{opt}".upcase)
#        else
#          flags += opt
#        end
#      end
#      self.class.glob(self.to_s, flags).collect{ |path| self.class.new(path) }
#    end
#
#    #
#    def first(*opts)
#      flags = 0
#      opts.each do |opt|
#        case opt when Symbol, String
#          flags += File.const_get("FNM_#{opt}".upcase)
#        else
#          flags += opt
#        end
#      end
#      file = self.class.glob(self.to_s, flags).first
#      file ? self.class.new(file) : nil
#    end

end
