require "fileutils"
require "pathname"

require_relative "src/lib/bookdown/parser"
require_relative "src/lib/bookdown/renderer"

include FileUtils

FILES = [
  "intro",
  "third_party_libs",
  "testing",
  "production",
]
task :default => [ :dist, :work, :site ] do
  parser = Bookdown::Parser.new(work_dir: "work", dist_dir: "dist")
  renderer = Bookdown::Renderer.new
  FILES.map { |file|
    Pathname("markdown/#{file}.md").expand_path
  }.map { |file|
    puts "Processing #{file}"
    parser.parse(file)
  }.each do |file|
    renderer.render(file,"site/#{file.basename(file.extname)}.html")
    cp_r "dist/images", "site"
  end
end

task :dist do
  mkdir_p "dist"
end

task :site do
  rm_rf "site"
  mkdir_p "site"
end

task :work do
  rm_rf "work"
  mkdir_p "work"
end
