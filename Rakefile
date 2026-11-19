# frozen_string_literal: true

require "minitest/test_task"
require "tmpdir"

Minitest::TestTask.create

desc "Lint Ruby and Markdown"
task :lint do
  sh "rubocop"
  sh "mdl", "--style", ".mdl_style.rb", "--ignore-front-matter", *Dir["*.md"]
end

desc "Type-check TypeScript and confirm assets/js/main.js is built from assets/js/main.ts"
task :typecheck do
  sh "tsc", "--project", "test"
  Dir.mktmpdir do |dir|
    sh "tsc", "--outDir", dir
    sh "diff", "-u", "assets/js/main.js", File.join(dir, "main.js") do |ok|
      ok || abort("assets/js/main.js is out of date. Run tsc to rebuild it from assets/js/main.ts.")
    end
  end
end

desc "Run TypeScript tests"
task :test_ts do
  sh "node", "--test", "test/**/*.test.ts"
end

task default: %i[lint typecheck test test_ts]
