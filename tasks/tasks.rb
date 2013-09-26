require 'yaml'
require 'parser'

namespace :burek do

  desc "Task passes through all views and reports any missing translations"
  task :fetch, [:locale] => [:environment] do |t,args|

    # CONFIG start
    search_folders = ['./app/views/**/*']
    translation_path = './config/locales/burek/'
    translation_placeholder = 'TODO'
    ignore_folders_for_key = ['.','app']
    locales = ['en','fi']
    # =========

    # Create translations folder if missing
    unless File.directory?(translation_path)
      Dir.mkdir(translation_path)
    end

    new_translations = {}
    # Iterate all defined subfolders subfolders
    search_folders.each do |folder|
      Dir.glob(folder) do |file_name|
        unless File.directory?(file_name)
          file = File.open(file_name, "rb")
          path = file_name.split('/')
          path.delete_if do |item|
            ignore_folders_for_key.include? item
          end
          path.pop
          filtered_path = path.join('/')
          contents = file.read
          matches = Burek::Parser.find_burek_calls(contents)
          matches.each do |value|
            key = filtered_path + "/" + value.downcase.gsub(' ','_')
            puts key
            new_translations[key] = value
          end
        end
      end
    end

    to_replace = {}
    # Create files for each locale
    locales.each do |locale|
      translations_hash = {}
      if File.exists?(translation_path + "test.#{locale}.yml")
        translations_hash = YAML::load_file(translation_path + "test.#{locale}.yml") #Load
      end

      translations_hash[locale.dup.force_encoding("UTF-8")] = {} unless translations_hash.has_key?(locale.dup.force_encoding("UTF-8"))
      new_translations.each do |key,value|
        cur_hash = translations_hash[locale.dup.force_encoding("UTF-8")]
        path_parts = key.split("/")

        regular_translation_key = path_parts.join('.')


        item_name = path_parts.pop

        to_replace[value] = regular_translation_key

        path_parts.each do |item|
          cur_hash[item] = {} unless cur_hash.has_key?(item)

          cur_hash = cur_hash[item]
        end
        cur_hash[item_name] = ( locale == locales.first ? value.dup.force_encoding("UTF-8") : translation_placeholder )
      end

      yaml = translations_hash.to_yaml
      clean_yaml = yaml.lines.to_a[1..-1].join
      puts clean_yaml
      File.write(translation_path + "test.#{locale}.yml", clean_yaml) #Store
    end

    # Replace all burek calls with regular translation calls
    search_folders.each do |folder|
      Dir.glob(folder) do |file_name|

      unless File.directory?(file_name)
        File.open(file_name, 'r') do |file|
          content = file.read
          processed_content = Burek::Parser.replace_burek_calls(content, to_replace)
          unless processed_content.nil?
            File.open(file_name, 'w') do |output_file|
              output_file.print processed_content
            end
          end
        end
      end

      end
    end

  end
  
end