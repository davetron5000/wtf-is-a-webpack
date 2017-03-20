require "fileutils"
require "pathname"
require "redcarpet"

require_relative "src/lib/bookdown/parser"

include FileUtils

FILES = [
  "intro",
  "third_party_libs",
  "testing",
  "production",
]
task :default => [ :dist, :work, :site ] do
  FILES.map { |file|
    Pathname("markdown/#{file}.md").expand_path
  }.map { |file|
    puts "Processing #{file}"
    Bookdown::Parser.new(work_dir: "work", dist_dir: "dist").parse(file)
  }.each do |file|
    renderer = Redcarpet::Render::HTML.new(
      with_toc_data: true
    )
    markdown = Redcarpet::Markdown.new(renderer,
                                       tables: true,
                                       no_intra_emphasis: true,
                                       fenced_code_blocks: true,
                                       autolink: true,
                                       disable_indented_code_blocks: true,
                                       strikethrough: true,
                                       superscript: true,
                                       highlight: true)

    File.open("site/#{file.basename(file.extname)}.html","w") do |html|
      html.puts(markdown.render(File.read(file)))
    end
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
