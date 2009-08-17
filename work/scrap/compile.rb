module Reap
  class Domain

    # Compile service (only autotools.rb supported at this time)
    #
    def compile_service
      @compile_service ||= (
        compiler = config.compiler || 'autotools'
        Reap.const_get(compiler.capitalize).new(self)
      )
      #@compile_service ||= CompileService.factory(compiler, self)
    end

    #

    def compiles?
      compile_service.compiles?
    end

    #

    #def compiles?
    #  Dir.chdir(source_folder) do
    #    not metadata.extensions.empty?
    #  end
    #end

    #

    def configure
      #Dir.chdir(source_folder) do
        compile_service.configure
      #end
    end

    #

    def compile
      #Dir.chdir(source_folder) do
        if buildspec.static
          compile_service.compile_static
        else
          compile_service.compile
        end
      #end
    end

    def clean
      #Dir.chdir(source_folder) do
        compile_service.clean
      #end
    end

    def distclean
      #Dir.chdir(source_folder) do
        compile_service.distclean
      #end
    end

  end
end

