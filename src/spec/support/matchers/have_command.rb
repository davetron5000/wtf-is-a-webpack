RSpec::Matchers.define :have_command do |klass,options|
  match do |queue|
    has_class = queue.map(&:class).include?(klass)
    if has_class && options
      supports_interface = queue.select { |object|
        options.keys.all? { |method|
          object.respond_to?(method)
        }
      }
      supports_interface.any? { |object|
        options.keys.all? { |method|
          object.send(method) == options[method]
        }
      }
    else
      has_class
    end
  end

  failure_message do |queue|
    "Queue was: #{queue.map(&:class).map(&:name).join(',')}"
  end
end
