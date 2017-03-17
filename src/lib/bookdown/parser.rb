require 'pathname'
require 'open3'
require 'json'
require 'pathname'
require 'fileutils'

require_relative "directives"

module Bookdown
  class Parser
    include FileUtils

    def initialize
      @work_dir = Pathname("work")
      @dist = Pathname("dist")
    end

    def parse(file)
      existing_add_to_directive = nil
      inside_package_json = false
      package_json = ""

      input = Pathname(file)
      output = @dist / input.basename
      File.open(output,"w") do |file|
        File.open(input) do |input|
          chdir @work_dir do
            input.readlines.each do |line|
              if line =~ /^!END PACKAGE_JSON *$/
                existing_package_json = JSON.parse(File.read("package.json"))
                puts "Inserting into package.json:\n#{package_json}"
                parsed_additions = JSON.parse(package_json)
                new_package_json = JSON.pretty_generate(existing_package_json.merge(parsed_additions))
                File.open("package.json","w") do |package_json_file|
                  package_json_file.puts(new_package_json)
                end
                file.puts "```json"
                file.puts new_package_json
                file.puts "```"
                inside_package_json = false
                package_json = ""
              elsif line =~ /^!END ADD_TO *$/
                file.puts "```"
                existing_add_to_directive = nil
              elsif inside_package_json
                package_json << line
              elsif existing_add_to_directive
                queue = existing_add_to_directive.append(line)
                queue.each do |command|
                  command.execute(file)
                end
              elsif line =~ /^!DUMP_CONSOLE (.*)$/
                html = $1
                exec_and_print("phantomjs ../src/dump_console.js #{html}",file, show_command: false)
              elsif line =~ /^!SCREENSHOT (.*)$/
                html,screenshot = $1.split(/\s+/)
                mkdir_p @dist / "images"
                exec_and_print("phantomjs ../src/screenshot.js #{html} #{@dist}/images/#{screenshot}",file) do |command,result|
                  file.puts "![screenshot](images/#{screenshot})"
                end
              elsif sh_directive = Bookdown::Directives::Sh.recognize(line)
                file.puts(sh_directive.execute)
              elsif line =~/^!PACKAGE_JSON *$/
                raise "already inside an PACKAGE_JSON" if inside_package_json
                inside_package_json = true
              elsif add_to_directive = Bookdown::Directives::AddTo.recognize(line)
                raise "already inside an ADD_TO" if existing_add_to_directive
                existing_add_to_directive = add_to_directive
                queue = existing_add_to_directive.execute
                queue.each do |command|
                  command.execute(file)
                end
              else
                file.puts line
              end
            end
          end
        end
      end
    end
    def language(filename)
      if filename =~ /\.js/
        "javascript"
      elsif filename =~ /\.html/
        "html"
      else
        raise "Can't determine language for #{filename}"
      end
    end

    def exec_and_print(command,io, show_command: true, show_stdout: true, &block)
      puts "Executing #{command}"
      io.puts "```"
      stdout,stderr,status = Open3.capture3(command)
      if status.success?
        if block.nil?
          io.puts "> #{command}" if show_command
          io.puts stdout if show_stdout
        else
          block.(command,stdout)
        end
      else
        raise status.inspect + "\n" + stdout + "\n" + stderr
      end
      io.puts "```"
    end
  end
end
