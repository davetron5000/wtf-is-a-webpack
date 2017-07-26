require "spec_helper"

require "fileutils"
require "logger"
require "pathname"
require "stringio"

require "bookdown/parser"

RSpec.describe Bookdown::Parser do
  let(:logger)  { instance_double(Logger) }
  let(:tmp_dir) { Pathname(Dir.mktmpdir) }
  let(:work_dir) { tmp_dir / "work" }
  let(:screenshots_dir) { tmp_dir / "screenshots_dir" }
  let(:output)  { tmp_dir / "out.md" }
  let(:input)   { tmp_dir / "input.md" }

  subject(:parser) {
    described_class.new(
      work_dir: work_dir,
      screenshots_dir: screenshots_dir,
      logger: logger
    )
  }
  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    FileUtils.mkdir_p work_dir
    FileUtils.mkdir_p screenshots_dir
  end
  describe "#parse" do
    context "single line directives" do
      context "DUMP_CONSOLE" do
        it "executes the html and puts the JavaScript console into the output" do
          write_input("!DUMP_CONSOLE #{create_html_file}")
          parser.parse(input: input, output: output)
          results = File.read(output)
          expect(results).to eq("```\nHERE WE GO!\n```\n")
        end
      end
      context "SCREENSHOT" do
        before do
          write_input("!SCREENSHOT \"Title goes here\" #{create_html_file} foo.png")
          parser.parse(input: input, output: output)
        end

        it "outputs an image tag" do
          results = File.read(output)
          expect(results).to eq("![Title goes here](images/foo.png)\n")
        end
        it "stores the image in the screenshots dir" do
          expect(File.exist?(screenshots_dir / "foo.png"))
        end
      end
      context "SH" do
        it "executes the command and puts it, and the output, into the file" do
          write_input("!SH echo 'this is a thing'")

          parser.parse(input: input, output: output)

          results = File.read(output)
          expect(results).to eq("```shell\n> echo 'this is a thing'\nthis is a thing\n```\n")
        end
      end
    end
    context "multi-line directives" do
      context "DO_AND_DUMP_CONSOLE" do
        it "creates a custom script with the embedded JavaScript and puts the console into the file" do
          write_input(
            "!DO_AND_DUMP_CONSOLE #{create_html_file}",
            "console.log('AND MORE!!');",
            "!END DO_AND_DUMP_CONSOLE"
          )

          parser.parse(input: input, output: output)

          results = File.read(output)
          expect(results).to eq("```\nHERE WE GO!\nAND MORE!!\n```\n")
        end
      end
      context "DO_AND_SCREENSHOT" do
        before do
          write_input(
            "!DO_AND_SCREENSHOT \"Title goes here\" #{create_html_file} foo.png",
            "console.log('This is some stuff');",
            "!END DO_AND_SCREENSHOT"
          )

          parser.parse(input: input, output: output)
        end

        it "outputs an image tag" do
          results = File.read(output)
          expect(results).to eq("![Title goes here](images/foo.png)\n")
        end
        it "stores the image in the screenshots dir" do
          expect(File.exist?(screenshots_dir / "foo.png"))
        end
      end
      context "PACKAGE_JSON" do
        before do
          File.open(work_dir / "package.json","w") do |file|
            file.puts({ foo: "bar" }.to_json)
          end
          write_input(
            "!PACKAGE_JSON",
            "{",
            "  \"scripts\": {",
            "    \"webpack\": \"$(yarn bin)/webpack\"",
            "  }",
            "}",
            "!END PACKAGE_JSON"
          )

          parser.parse(input: input, output: output)
        end

        it "outputs the additional JSON to the file" do
          results = File.read(output)
          expect(results).to eq("```json\n{\n  \"scripts\": {\n    \"webpack\": \"$(yarn bin)/webpack\"\n  }\n}\n```\n")
        end
        it "updates the package.json in the work dir" do
          updated_package_json = JSON.parse(File.read(work_dir / "package.json"))
          expect(updated_package_json["foo"]).to eq("bar")
          expect(updated_package_json["scripts"]["webpack"]).to eq("$(yarn bin)/webpack")
        end
      end
      context "CREATE_FILE" do
        before do
          write_input(
            "!CREATE_FILE foo/bar/blah.js",
            "import bar from 'bar'",
            "",
            "bar.crud();",
            "!END CREATE_FILE"
          )

          parser.parse(input: input, output: output)
        end

        it "output the created file's contents to the file" do
          results = File.read(output)
          expect(results).to eq("```javascript\nimport bar from 'bar'\n\nbar.crud();\n```\n")
        end

        it "creates the file with the given contents" do
          javascript = File.read(work_dir / "foo" / "bar" / "blah.js")
          expect(javascript).to eq("import bar from 'bar'\n\nbar.crud();\n")
        end

      end
      context "EDIT_FILE" do
        let(:expected_html) {
          "<!DOCTYPE html>\n<html>\n  <head>\n    <script>\n      console.log(\"HERE WE GO!\");\n    </script>\n  </head>\n  <body>\n<!-- start new code -->\n<h2>subtitles</h2>\n<h3>sub-subtitles</h3>\n<!-- end new code -->\n  </body>\n</html>\n      \n"
        }
        let(:html_file) { create_html_file }

        before do
          write_input(
            "!EDIT_FILE #{html_file} <!-- -->",
            "{",
            "  \"match\": \"    <h1>\",",
            "  \"replace_with\": [",
            "    \"<h2>subtitles</h2>\",",
            "    \"<h3>sub-subtitles</h3>\"",
            "  ]",
            "}",
            "!END EDIT_FILE"
          )

          parser.parse(input: input, output: output)
        end

        it "inserts the edited file into a fenced code block" do
          results = File.read(output)
          expect(results).to eq("```html\n#{expected_html}```\n")
        end

        it "edits the file with based on the instructions" do
          html = File.read(html_file)
          expect(html).to eq(expected_html)
        end
      end
    end
    context "no directive" do
      it "writes the line out directly" do
        write_input("Just some regular text")
        parser.parse(input: input, output: output)
        results = File.read(output)
        expect(results).to eq("Just some regular text\n")
      end
    end
  end
  def write_input(*strings)
    File.open(input,"w") do |file|
      strings.each do |string|
        file.puts(string)
      end
    end
  end

  def create_html_file
    html_file = tmp_dir / "index.html"
    File.open(html_file,"w") do |file|
      file.puts %{<!DOCTYPE html>
<html>
  <head>
    <script>
      console.log("HERE WE GO!");
    </script>
  </head>
  <body>
    <h1>HELLO!</h1>
  </body>
</html>
      }
    end
    html_file
  end
end
