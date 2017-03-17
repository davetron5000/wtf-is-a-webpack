FILES = [
  "intro",
  "third_party_libs",
  "testing",
  "production",
]
task :default do
  args = FILES.map { |file|
    "'markdown/#{file}.md'"
  }.join(" ")
  sh("ruby src/mk_md.rb #{args}")
end
