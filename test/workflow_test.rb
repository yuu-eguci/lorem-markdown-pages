# frozen_string_literal: true

require "test_helper"
require "yaml"

class WorkflowTest < Minitest::Test
  WORKFLOWS = Dir[File.expand_path("../.github/workflows/*.yml", __dir__)]

  def test_actions_are_pinned_to_commit_shas
    WORKFLOWS.each do |path|
      File.readlines(path).grep(/^\s*-?\s*uses:/).each do |line|
        assert_match(%r{uses: [\w.-]+/[\w.-]+@\h{40} # v\d}, line, "#{File.basename(path)}: #{line.strip}")
      end
    end
  end

  def test_workflows_only_read_contents
    WORKFLOWS.each do |path|
      assert_equal({ "contents" => "read" }, YAML.safe_load_file(path)["permissions"], File.basename(path))
    end
  end
end
