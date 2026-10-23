# frozen_string_literal: true

require "minitest/test_task"

Minitest::TestTask.create

desc "Lint Ruby and Markdown"
task :lint do
  sh "rubocop"
  sh "mdl", "--style", ".mdl_style.rb", *Dir["*.md"]
end

task default: %i[lint test]
