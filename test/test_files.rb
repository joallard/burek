require 'test/unit'
require 'parser'
require 'fileutils'
require 'config'
require 'core'

class BurekTesting < Test::Unit::TestCase

  def setup
    @temp_folder = "./temp/"
    @examples_folder = "./test/examples/"
    @views_folder = @temp_folder+"views/"
    @translations_folder = @temp_folder+"translations/"

    # Recreate temp folder
    if File.directory?(@temp_folder)
      FileUtils.rm_rf(@temp_folder)
    end
    Dir.mkdir(@temp_folder)
    Dir.mkdir(@views_folder)
    Dir.mkdir(@translations_folder)

    # Set config variables
    Burek.set_config :search_folders, [@views_folder+"**/*"]
    Burek.set_config :translations_path, @translations_folder
    Burek.set_config :ignore_folders_for_key, ['.','temp','views']
  end

  def teardown
    if File.directory?(@temp_folder)
      FileUtils.rm_rf(@temp_folder)
    end
  end

  def test_depth_0
    setup
    copy_example("test1.html.erb","/")
    Burek::Core.run_burek
    assert_file_contents(@views_folder + "/test1.html.erb", "<h1><%= t('welcome') %></h1>")
    teardown
  end

  def test_depth_1
    setup
    copy_example("test1.html.erb","/level1/")
    Burek::Core.run_burek
    assert_file_contents(@views_folder + "/level1/test1.html.erb", "<h1><%= t('level1.welcome') %></h1>")
    teardown
  end

  def test_depth_2
    setup
    copy_example("test1.html.erb","/level1/l2/")
    Burek::Core.run_burek
    assert_file_contents(@views_folder + "/level1/l2/test1.html.erb", "<h1><%= t('level1.l2.welcome') %></h1>")
    teardown
  end

  def test_depth_3
    setup
    copy_example("test1.html.erb","/level1/l2/l3/")
    Burek::Core.run_burek
    assert_file_contents(@views_folder + "/level1/l2/l3/test1.html.erb", "<h1><%= t('level1.l2.l3.welcome') %></h1>")
    teardown
  end

  def copy_example(example, target_folder)
    target = "" if target_folder == "/"

    # Create folders if target is nested
    target_folder_parts = target_folder.split("/")
    current_folder = @views_folder
    target_folder_parts.each do |folder|
      current_folder += "#{folder}/"
      unless File.directory?(current_folder)
        Dir.mkdir(current_folder)
      end
    end

    FileUtils.cp(@examples_folder+example, @views_folder + target_folder + example)
  end

  def assert_file_contents(path, expected_content)
    File.open(path, "rb") do |file|
      content = file.read
      assert_equal expected_content, content
    end
  end


end