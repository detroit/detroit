if RUBY_VERSION >= '1.9'

  module Redline
    BasicObject = ::BasicObject
  end

else

  module Redline

    # BasicObject provides an abstract base class with no predefined
    # methods (except for <tt>\_\_send__</tt> and <tt>\_\_id__</tt>).
    # BasicObject is useful as a base class when writing classes that
    # depend upon <tt>method_missing</tt> (e.g. dynamic proxies).
    #
    # BasicObject is based on BlankSlate by Jim Weirich.
    #
    # Copyright 2004, 2006 by Jim Weirich (jim@weirichhouse.org).
    # All rights reserved.

    class BasicObject #:nodoc:

      # Hide the method named +name+ in the BlankSlate class.  Don't
      # hide +instance_eval+ or any method beginning with "__".
      def self.hide(name)
        name = name.to_s
        if instance_methods.include?(name) and
          name !~ /^(__|instance_eval|instance_exec)/
          @hidden_methods ||= {}
          @hidden_methods[name.to_sym] = instance_method(name)
          undef_method name
        end
      end

      def self.find_hidden_method(name)
        @hidden_methods ||= {}
        @hidden_methods[name.to_sym] || superclass.find_hidden_method(name)
      end

      # Redefine a previously hidden method so that it may be called on a blank
      # slate object.
      def self.reveal(name)
        hidden_method = find_hidden_method(name)
        fail "Don't know how to reveal method '#{name}'" unless hidden_method
        define_method(name, hidden_method)
      end

      #  
      instance_methods.each { |m| hide(m) }
    end
  end

  # Since Ruby is very dynamic, methods added to the ancestors of
  # BlankSlate <em>after BlankSlate is defined</em> will show up in the
  # list of available BlankSlate methods.  We handle this by defining a
  # hook in the Object and Kernel classes that will hide any method
  # defined after BlankSlate has been loaded.
  #
  module Kernel
    class << self
      alias_method :basic_object_method_added, :method_added

      # Detect method additions to Kernel and remove them in the
      # BasicObject class.
      def method_added(name)
        result = basic_object_method_added(name)
        return result if self != Kernel
        AE::BasicObject.hide(name)
        result
      end
    end
  end

  # Same as above, except in Object.
  #
  class Object
    class << self
      alias_method :basic_object_method_added, :method_added

      # Detect method additions to Object and remove them in the
      # BlankSlate class.
      def method_added(name)
        result = basic_object_method_added(name)
        return result if self != Object
        AE::BasicObject.hide(name)
        result
      end

      def find_hidden_method(name)
        nil
      end
    end
  end

  # Also, modules included into Object need to be scanned and have their
  # instance methods removed from blank slate.  In theory, modules
  # included into Kernel would have to be removed as well, but a
  # "feature" of Ruby prevents late includes into modules from being
  # exposed in the first place.
  #
  class Module #:nodoc:
    alias basic_object_original_append_features append_features
    def append_features(mod)
      result = basic_object_original_append_features(mod)
      return result if mod != Object
      instance_methods.each do |name|
        AE::BasicObject.hide(name)
      end
      result
    end
  end

end
