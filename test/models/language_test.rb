require "test_helper"

class LanguageTest < ActiveSupport::TestCase
  test "cannot save language without name" do
    language = Language.new(source_file: "fake source file", run_cmd: "fake run cmd")
    assert_not language.save, "Saved the language without a name"
  end

  test "cannot save language without source file" do
    language = Language.new(name: "fake name", run_cmd: "fake run cmd")
    assert_not language.save, "Saved the language without a source file"
  end

  test "cannot save language without run cmd" do
    language = Language.new(name: "fake name", source_file: "fake source file")
    assert_not language.save, "Saved the language without a run cmd"
  end
  test "can save language when necessary fields are present" do
    language = Language.new(name: "fake name", source_file: "fake source file", run_cmd: "fake run cmd")
    assert language.save
  end
end
