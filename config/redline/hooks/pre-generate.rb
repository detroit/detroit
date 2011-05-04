#!/usr/bin/env ruby
file  = "lib/#{project.metadata.name}.rb"
text1 = read(file)
text2 = text1.sub(/VERSION\s*\=\s*\S+/, %{VERSION = "#{project.metadata.version}"})
if text1 != text2
  write(file, text2)
  report "Updated #{file}"
else
  report "Already current #{file}"
end

