require "pathname"
require_relative "src/lib/bookdown/builder"

desc "Build it all"
task :default do
  book = Bookdown::Book.new(
                src_dir: "src",
      static_images_dir: "images",
           markdown_dir: "markdown",
               work_dir: "work",
    parsed_markdown_dir: "parsed_markdown",
               site_dir: Pathname("../what-problem-does-it-solve.com/site").expand_path / "webpack"
  )

  builder = Bookdown::Builder.new
  builder.build(book)
end
