module Promenade::Plugins

  # QED Plugin - This service plugin runs your QED test-documents
  # and can generate QEDocs too.
  #
  # If the `output` options is set to `nil` then the document
  # stop will be bypassed.
  #
  # TODO: How to abort track if fail?
  class Qed < Service

    # Options conform to RedTools::Testrb class.
    def self.options
      super(RedTools::Qed)
    end

    # Run QED test-documents.
    def test
      tool.test
    end

    # Generate documentation.
    def document
      tool.document
    end

    # Mark QEDocs directory as out of date.
    def reset
      tool.reset
    end

    # Remove QEDocs directory.
    def purge
      tool.purge
    end

    # If output is set to `nil`, then don't document.
    def stop?(name)
      unless options['output']
        return false if %w{document reset purge}.include?(name.to_s)
      end
      super(name)
    end

    private

    #
    def tool
      @tool ||= RedTools::Qed(options)
    end

    #
    def initialize_requires
      require 'redtools'
    end

  end

end

