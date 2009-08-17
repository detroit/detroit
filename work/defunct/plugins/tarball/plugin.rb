require 'reap/plugins/base_pack'

module Reap
module Plugins

  # = Tarball Package Plugin
  #
  class Tarball < Plugin::PackPlugin

    pipeline :main, :package

    # TODO: Add rest or clean ?
    #pipeline :main, :reset

    def extension ; '.tar.gz' ; end

    # Create a tar gzip source package.
    #
    def package
      unless package_needed? or force?
        report_package_already_built(package_file)
        return
      end

      status("tar -cxf #{package_file}")

      return if dryrun?

      file = nil

      stage(extension)

      cd(project.tmp) do
        rm package_file if exist?(package_file)
        file = tgz(stage_name)
      end

      file = transfer(file, project.pack)

      report_package_built(file)

      return file
    end

  end

end
end

