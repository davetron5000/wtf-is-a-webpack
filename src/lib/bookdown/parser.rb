require 'pathname'
require 'open3'
require 'json'
require 'pathname'
require 'fileutils'

require_relative "directives"
require_relative "command_executor"

module Bookdown
  class Parser
    include FileUtils

    def initialize(work_dir: , screenshots_dir:, logger:)
      @work_dir        = Pathname(work_dir)
      @screenshots_dir = Pathname(screenshots_dir)
      @logger          = logger
    end

    def directives
      {
        Bookdown::Directives::JsConsole       => [ :line ],
        Bookdown::Directives::Screenshot      => [ :line, :screenshots_dir ],
        Bookdown::Directives::Sh              => [ :line ],
        Bookdown::Directives::EditFile        => [ :line ],
        Bookdown::Directives::DoAndScreenshot => [ :line, :screenshots_dir ],
        Bookdown::Directives::DoAndJsConsole  => [ :line ],
        Bookdown::Directives::PackageJson     => [ :line ],
        Bookdown::Directives::CreateFile      => [ :line ],
        Bookdown::Directives::Graphviz        => [ :line, :screenshots_dir ],
      }
    end

    def parse(input: , output:)
      existing_directive = nil
      existing_directive_line_no = nil

      File.open(output,"w") do |file|
        File.open(input) do |input|
          chdir @work_dir do
            line_no = 0
            input.readlines.each do |line|
              line_no += 1
              if existing_directive
                commands = existing_directive.append(line)
                command_executor.execute_all(commands,file)
                unless existing_directive.continue?
                  existing_directive = nil
                end
              elsif directive = detect_directive(line)
                existing_directive_line_no = line_no
                commands = directive.execute
                command_executor.execute_all(commands,file)
                if directive.continue?
                  existing_directive = directive
                end
              else
                file.puts line
              end
            end
          end
        end
      end
      if existing_directive != nil
        raise "Still inside a #{existing_directive.class} from line #{existing_directive_line_no} - missing a close tag?"
      end
      output
    end

  private

    def detect_directive(line)
      directive = directives.map { |directive_klass,args_template|
        args = args_template.zip([line,@screenshots_dir]).map { |_| _[1] }
        @logger.debug("Checking #{directive_klass} against #{args}")
        directive_klass.recognize(*args)
      }.compact.first
      if directive
        directive
      elsif line =~ /^\![A-Z]+/
        raise "Unknown directive #{line}"
      else
        nil
      end
    end

    def command_executor
      @command_executor ||= Bookdown::CommandExecutor.new(logger: @logger)
    end
  end
end
