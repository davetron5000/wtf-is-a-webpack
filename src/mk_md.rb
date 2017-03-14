#!/usr/bin/ruby

require 'fileutils'
require 'open3'
require 'json'
require 'pathname'

include FileUtils

mkdir_p "dist"
rm_rf "work"
mkdir_p "work"

inside_add_to = false
inside_package_json = false
package_json = ""

def language(filename)
  if filename =~ /\.js/
    "javascript"
  elsif filename =~ /\.html/
    "html"
  else
    raise "Can't determine language for #{filename}"
  end
end

def exec_and_print(command,io, show_command: true, show_stdout: true)
  puts "Executing #{command}"
  io.puts "```"
  stdout,stderr,status = Open3.capture3(command)
  if status.success?
    io.puts "> #{command}" if show_command
    io.puts stdout if show_stdout
  else
    raise status.inspect + "\n" + stdout + "\n" + stderr
  end
  io.puts "```"
end

ARGV.each do |input|
  basename = Pathname.new(input).basename
  File.open("dist/#{basename}","w") do |file|
    File.open(input) do |input|
      chdir "work" do
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
            inside_add_to = false
          elsif inside_package_json
            package_json << line
          elsif inside_add_to
            File.open(inside_add_to,"a") do |file_to_add_to|
              file.puts line
              file_to_add_to.puts line
            end
          elsif line =~ /^!DUMP_CONSOLE (.*)$/
            html = $1
            exec_and_print("phantomjs ../src/dump_console.js #{html}",file, show_command: false)
          elsif line =~ /^!SH({.*})? (.*)$/
            command,options = if $2.nil?
                                [$1,[]]
                              else
                                [$2,$1.to_s.gsub(/[{}]/,'').split(/,/)]
                              end
            exec_and_print(command,file,show_stdout: !options.include?("quiet"))
          elsif line =~/^!PACKAGE_JSON *$/
            raise "already inside an PACKAGE_JSON" if inside_package_json
            inside_package_json = true
          elsif line =~/^!ADD_TO (.*)$/
            raise "already inside an ADD_TO" if inside_add_to
            inside_add_to = $1
            file.puts "```#{language(inside_add_to)}"
          else
            file.puts line
          end
        end
      end
    end
  end
end
