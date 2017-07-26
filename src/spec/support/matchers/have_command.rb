class HaveCommandMatchData
  def initialize(klass,options,queue)
    @klass = klass
    @options = options
    @queue = queue

    @candidates = @queue.select { |_| _.class == @klass }
    @supports_interface = @candidates.select { |object|
      @options.keys.all? { |method|
        object.respond_to?(method)
      }
    }
    @analysis = @supports_interface.map { |object|
      [
        object,
        @options.keys.map { |method|
          [ method, @options[method], object.send(method) ]
        }
      ]
    }
  end

  def matches?
    @analysis.detect { |(object,result)|
      result.all? { |(_,expected,got)|
        expected == got
      }
    }
  end

  def error
    if @candidates.empty?
      "Nothing in queue was a #{@klass}:\n#{@queue.inspect}"
    elsif @supports_interface.empty?
      "#{@klass} instances in queue don't respond to all of #{@options.keys.inspect}:\n#{@queue.inspect}"
    else
      @analysis.map { |(object,result)|
        result.select { |(_,expected,got)|
          expected != got
        }.map { |(method,expected,got)|
          "#{method} returned a #{got.class}:\n#{got}\nwas expecting a #{expected.class}:\n#{expected}"
        }.join("\n\n")
      }.join("\n")
    end
  end

end
RSpec::Matchers.define :have_command do |klass,options|
  match do |queue|
    options ||= {}
    data = HaveCommandMatchData.new(klass,options,queue)
    data.matches?
  end

  failure_message do |queue|
    data = HaveCommandMatchData.new(klass,options,queue)
    data.error
  end
end
