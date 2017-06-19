# Bookdown - make a technical book in markdown with "live" code examples

When writing technical books or documents, there is always a challenge in keeping the text updated with the
example code.  In an ideal world, your code is 100% executable and working in the way your writing says it
is.

Bookdown is an attempt to remedy that.

You author your text in markdown that has been augmented with special pre-processor tags.  These tags can
run commands, create & edit files, and even do limited stuff in the browser.

## Example

Suppose you want to teach someone about the `<h1>` tag. You might write this:


```
The <h1> tag sets text as the top-level heading.

To see it in action, let's create a place to work

!SH mkdir html

Now, create a simple HTML page:

!CREATE_FILE html/index.html
<!DOCTYPE html>
<html>
  <head><title>My Page!</title></head>
  <body>
    This is my page
  </body>
</html>
!END CREATE_FILE

To set “This is my page” as your header, wrap it in `<h1>` tags:

!EDIT_FILE html/index.html <!-- -->
{
  "match": "    This is my page",
  "replace_with": [
    "    <h1>",
    "      This is my page",
    "    </h1>"
  ]
}
!END EDIT_FILE

And now, it's rendered as a header:

!SCREENSHOT "A wild header appears" html/index.html header.png
```

Bookdown converts the above markdown into standard markdown by processing the directives that start with a
`!`.  The result can then be rendered into HTML for viewing on a page.


### Basic Rakefile

Here is a Rakefile you can use to build your project

```ruby
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
```
