module Reap

  class Project

    # Create web index.html from README. (Not yet used)

    def html
      status_title "Creating HTML documents"

      require 'rdoc/markup/simple_markup'
      require 'rdoc/markup/simple_markup/to_html'

      options = configure_options(options, 'html')

      output = options['output']
      files  = options['files']
      style  = options['css']

      output ||= 'doc'
      files  ||= '[A-Z]*'
      style  ||= Dir.glob('*.css').first

      files = Dir.glob(files)

      s = SM::SimpleMarkup.new
      h = SM::ToHtml.new

      files.each do |file|
        unless File.exist?(file)
          puts "Warning: file does not exist -- #{file}"
        end
      end

      mkdir_p(output) unless dryrun?

      files.each do |file|
        name = file.downcase.chomp('.txt')
        if /^readme/ =~ name
          name = "index"
        end
        path = File.join(output, name + '.html')

        next unless out_of_date?(path, file)

        title = "#{package.title} #{name.upcase}"

        input  = File.read(file)
        output = s.convert(input, h)  # FIX

        text = ''
        text << %{<html>}
        text << %{<head>}
        text << %{  <title>#{title}<title>}
        text << %{  <link rel="stylesheet" TYPE="text/css" HREF="#{style}">} if style
        text << %{</head>}
        text << %{<body>}
        text << output
        text << %{</body>}
        text << %{</html>}

        write(path, text)

        puts "Created #{path}"
      end
    end

  end

end

