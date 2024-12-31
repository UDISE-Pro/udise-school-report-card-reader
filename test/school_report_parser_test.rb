require 'test/unit'
require 'yaml'
require 'csv'
require_relative '../school_report_parser'
require 'fileutils'

class SchoolReportParserTest < Test::Unit::TestCase
  def setup
    @schools = ['carmel-2223', 'jhita-2223', 'kachora-2223']
    
    @schools.each do |school|
      if File.exist?("./#{school}/#{school}.yml")
        FileUtils.cp("./#{school}/#{school}.yml", "./#{school}/#{school}_original.yml")
      end
    end
    
    system('./parse_report.sh')
    
    @benchmark_yamls = {}
    @schools.each do |school|
      @benchmark_yamls[school] = safe_yaml_load("./#{school}/#{school}.yml")
    end
  end

  def safe_yaml_load(file_path)
    YAML.safe_load_file(file_path, permitted_classes: [CSV::Row])
  end

  def test_yaml_generation_matches_benchmark
    @schools.each do |school|
      SchoolReportParser.extract_to_text("./#{school}/#{school}.pdf")
      generated_yaml = safe_yaml_load("./#{school}/#{school}.yml")
      assert_equal @benchmark_yamls[school], generated_yaml, 
        "Generated YAML for #{school} does not match the benchmark"
    end
  end

  def teardown
    @schools.each do |school|
      if File.exist?("./#{school}/#{school}_original.yml")
        FileUtils.mv("./#{school}/#{school}_original.yml", "./#{school}/#{school}.yml")
      end
    end
  end
end 