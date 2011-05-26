#__DIR__ = File.dirname(__FILE__)

#Dir[File.join(__DIR__, 'core_ext', '*.rb')].each do |file|
#  require file
#end

#require 'facets'
require 'facets/to_hash'
require 'facets/module/basename'
require 'facets/module/alias_accessor'
require 'facets/pathname'

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
    split(/[:;,\n]/).map{ |s| s.strip }
  end

end

# TODO: Replace these with facets/shellwords !!!

#
class Array #:nodoc:

  # Convert an array into commandline parameters.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]

  def to_console
    #flags = (Hash===last ? pop : {})
    #flags = flags.to_console
    #flags + ' ' + join(" ")
    to_argv.join(' ')
  end

  # TODO: DEPRECATE
  alias_method :to_params, :to_console

  #
  def to_argv
    flags = (Hash===last ? pop : {})
    flags = flags.to_argv
    flags + self
  end

#   def to_console
#     flags = (Hash===last ? pop : {})
#     flags = flags.collect do |f,v|
#       m = f.to_s.size == 1 ? '-' : '--'
#       case v
#       when Array
#         v.collect{ |e| "#{m}#{f} '#{e}'" }.join(' ')
#       when true
#         "#{m}#{f}"
#       when false, nil
#         ''
#       else
#         "#{m}#{f} '#{v}'"
#       end
#     end
#     return (flags + self).join(" ")
#   end

end

class Hash

  # Convert a Hash into command line arguments.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]
  def to_console
    to_argv.join(' ')
  end

  # Convert a Hash into command line parameters.
  # The array is accepted in the format of Ruby
  # method arguments --ie. [arg1, arg2, ..., hash]
  def to_argv
    flags = map do |f,v|
      m = f.to_s.size == 1 ? '-' : '--'
      case v
      when Array
        v.collect{ |e| "#{m}#{f}='#{e}'" }.join(' ')
      when true
        "#{m}#{f}"
      when false, nil
        ''
      else
        "#{m}#{f}='#{v}'"
      end
    end
  end

  # Turn a hash into arguments.
  #
  #   h = { :list => [1,2], :base => "HI" }
  #   h.argumentize #=> [ [], { :list => [1,2], :base => "HI" } ]
  #   h.argumentize(:list) #=> [ [1,2], { :base => "HI" } ]
  #
  def argumentize(args_field=nil)
    config = dup
    if args_field
      args = [config.delete(args_field)].flatten.compact
    else
      args = []
    end
    args << config
    return args
  end

  alias_method :command_vector, :argumentize

end

