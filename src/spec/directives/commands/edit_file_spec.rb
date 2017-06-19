require "spec_helper"
require "logger"
require "stringio"
require "pathname"
require "tmpdir"

require "bookdown/directives/commands/edit_file"

RSpec.describe Bookdown::Directives::Commands::EditFile do
  describe "#execute" do
    let(:logger)               { instance_double(Logger) }
    let(:io)                   { StringIO.new }
    let(:tmpdir)               { Pathname(Dir.mktmpdir) }
    let(:file_to_edit)         { tmpdir / "foo.html" }
    let(:start_comment)        { "<!--" }
    let(:end_comment)          { "-->"  }
    let(:editing_instructions) { [] }

    subject(:command) { described_class.new(file_to_edit,start_comment,end_comment,editing_instructions) }

    before do
      File.open(file_to_edit,"w") do |file|
        file.puts %{<html>
  <head>
    <script>
      console.log("This is JS");
    </script>
  </head>
  <body>
  <!-- start new code -->
    <h1>This is a header</h1>
  <!-- end new code -->
  </body>
</html>}
      end
      allow(logger).to receive(:info)
      allow(logger).to receive(:debug)
    end

    context "insert_before" do
      let(:editing_instructions) {
        [
          {
            "match" => "    <h1>",
            "insert_before" => [
              "<aside>",
              "  <h1>An aside</h1>",
              "</aside>"
            ]
          },
          {
            "match" => "  </body>",
            "insert_before" => [
              "<footer>Done</footer>"
            ]
          }
        ]
      }
      it "inserts the new code before the matched line, demarcating it with comments, removing any previous ones" do
        command.execute(io,logger)
        new_file_contents = File.read(file_to_edit)
        expect(new_file_contents).to eq(%{<html>
  <head>
    <script>
      console.log("This is JS");
    </script>
  </head>
  <body>
<!-- start new code -->
<aside>
  <h1>An aside</h1>
</aside>
<!-- end new code -->
    <h1>This is a header</h1>
<!-- start new code -->
<footer>Done</footer>
<!-- end new code -->
  </body>
</html>
})
      end
      it "logs about it" do
        command.execute(io,logger)
        expect(logger).to have_received(:info).with("Inserting '<aside>'")
        expect(logger).to have_received(:info).with("Inserting '  <h1>An aside</h1>'")
        expect(logger).to have_received(:info).with("Inserting '</aside>'")
        expect(logger).to have_received(:info).with("Inserting '<footer>Done</footer>'")
      end
      it "outputs the entire file contents to the IO" do
        command.execute(io,logger)
        new_file_contents = File.read(file_to_edit)
        expect(io.string).to eq(new_file_contents)
      end
    end
    context "insert_after" do
      let(:editing_instructions) {
        [
          {
            "match" => "    <h1>",
            "insert_after" => [
              "<aside>",
              "  <h1>An aside</h1>",
              "</aside>"
            ]
          },
          {
            "match" => "  </body>",
            "insert_after" => [
              "<footer>Done</footer>"
            ]
          }
        ]
      }
      it "inserts the new code after the matched line, demarcating it with comments, removing any previous ones" do
        command.execute(io,logger)
        new_file_contents = File.read(file_to_edit)
        expect(new_file_contents).to eq(%{<html>
  <head>
    <script>
      console.log("This is JS");
    </script>
  </head>
  <body>
    <h1>This is a header</h1>
<!-- start new code -->
<aside>
  <h1>An aside</h1>
</aside>
<!-- end new code -->
  </body>
<!-- start new code -->
<footer>Done</footer>
<!-- end new code -->
</html>
})
      end
      it "logs about it" do
        command.execute(io,logger)
        expect(logger).to have_received(:info).with("Inserting '<aside>'")
        expect(logger).to have_received(:info).with("Inserting '  <h1>An aside</h1>'")
        expect(logger).to have_received(:info).with("Inserting '</aside>'")
        expect(logger).to have_received(:info).with("Inserting '<footer>Done</footer>'")
      end
      it "outputs the entire file contents to the IO" do
        command.execute(io,logger)
        new_file_contents = File.read(file_to_edit)
        expect(io.string).to eq(new_file_contents)
      end
    end
    context "replace_with" do
      let(:editing_instructions) {
        [
          {
            "match" => "    <h1>",
            "replace_with" => [
              "<aside>",
              "  <h1>An aside</h1>",
              "</aside>"
            ]
          },
          {
            "match" => "  </body>",
            "replace_with" => [
              "<footer>Done</footer>"
            ]
          }
        ]
      }
      it "replaces the matched line with the new code, demarcating it with comments, removing any previous ones" do
        command.execute(io,logger)
        new_file_contents = File.read(file_to_edit)
        expect(new_file_contents).to eq(%{<html>
  <head>
    <script>
      console.log("This is JS");
    </script>
  </head>
  <body>
<!-- start new code -->
<aside>
  <h1>An aside</h1>
</aside>
<!-- end new code -->
<!-- start new code -->
<footer>Done</footer>
<!-- end new code -->
</html>
})
      end
      it "logs about it" do
        command.execute(io,logger)
        expect(logger).to have_received(:info).with("Inserting '<aside>'")
        expect(logger).to have_received(:info).with("Inserting '  <h1>An aside</h1>'")
        expect(logger).to have_received(:info).with("Inserting '</aside>'")
        expect(logger).to have_received(:info).with("Inserting '<footer>Done</footer>'")
      end
      it "outputs the entire file contents to the IO" do
        command.execute(io,logger)
        new_file_contents = File.read(file_to_edit)
        expect(io.string).to eq(new_file_contents)
      end
    end
    context "unknown editing instruction" do
      let(:editing_instructions) {
        [
          {
            "match" => "    <h1>",
            "munge_with" => [
              "<aside>",
              "  <h1>An aside</h1>",
              "</aside>"
            ]
          },
          {
            "match" => "  </body>",
            "replace_with" => [
              "<footer>Done</footer>"
            ]
          }
        ]
      }
      it "raises a useful error message" do
        expect {
          command.execute(io,logger)
        }.to raise_error("Matched '    <h1>This is a header</h1>', but don't understand instruction 'munge_with'")
      end
    end
    context "some editing instructions did not apply" do
      let(:editing_instructions) {
        [
          {
            "match" => "  <h1>",
            "munge_with" => [
              "<aside>",
              "  <h1>An aside</h1>",
              "</aside>"
            ]
          },
          {
            "match" => "</body>",
            "replace_with" => [
              "<footer>Done</footer>"
            ]
          }
        ]
      }
      it "raises a useful error message" do
        expect {
          command.execute(io,logger)
        }.to raise_error(/Didn't find a match for '  <h1>', '<\/body>'. File was/)
      end
    end
  end
end
