RSpec::Matchers.define :be_single_line_directive do
  match do |directive|
    directive.continue? == false &&
      directive.append("foo") == []
  end

  failure_message do |queue|
    if directive.continue?
      "#continue? returned true instead of false"
    else
      "#append() returned commands instead of []"
    end
  end
end
