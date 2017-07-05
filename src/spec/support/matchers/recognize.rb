class RecognizeMatchData
  def initialize(klass,line,extra_arg,as)
    @klass = klass
    @line = line
    @instance = if @klass.method(:recognize).arity == 1
                  @klass.recognize(@line)
                else
                  @klass.recognize(@line,extra_arg)
                end
    @options = as.fetch(:as)
  end

  def match?
    class_instance? && respond_to_methods?
  end

  def error(negated=false)
    if class_instance?
      if negated == :negated
        "Didn't expect #{@options.inspect}"
      else
        mismatched_methods.map { |(method,expected,got)|
          "#{method} returned '#{got}' instead of '#{expected}'"
        }
      end
    else
      if negated == :negated
        "Didnt' expected a #{@klass}"
      else
        "Expected a #{@klass}, but got a #{@instance.class}"
      end
    end
  end

private

  def class_instance?
    @instance.class == @klass
  end

  def respond_to_methods?
    mismatched_methods.empty?
  end

  def mismatched_methods
    @options.map { |method,value|
      [method,value,@instance.send(method)]
    }.reject { |(method,expected,got)|
      got == expected
    }
  end
end
RSpec::Matchers.define :recognize do |*args|
  line,extra_arg,as = if args.length == 1
    [args[0],nil,{as: {}}]
  elsif args.length == 2 && args[1].kind_of?(Hash) && args[1].key?(:as)
    [args[0],nil,args[1]]
  else
    options = args[2] || {}
    options[:as] ||= {}
    [args[0],args[1],options]
  end

  match do |klass|
    match_data = RecognizeMatchData.new(klass,line,extra_arg,as)
    match_data.match?
  end

  failure_message do |klass|
    RecognizeMatchData.new(klass,line,extra_arg,as).error
  end
  failure_message_when_negated do |klass|
    RecognizeMatchData.new(klass,line,extra_arg,as).error(:negated)
  end
end
