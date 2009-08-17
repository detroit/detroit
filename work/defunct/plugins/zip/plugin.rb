require 'reap/plugins/base_pack'

module Reap
module Plugins

  # = Zip Package Service
  #
  class Zip < Plugin::PackPlugin

    pipeline :main, :package

    # TODO: Add reset clean ?.
    #pipeline :main, :reset

    def extension ; '.zip' ; end

    # Create a zip source package.
    #
    def package
      unless package_needed? or force?
        report_package_already_built(package_file)
        return
      end

      status("zip -r #{package_file} .")

      return if dryrun?

      file = nil

      stage(extension)

      cd(project.tmp) do
        rm package_file if exist?(package_file)
        file = zip(stage_name)
      end

      file = transfer(file, project.pack)

      report_package_built(file)

      return file
    end

  end

end
end

