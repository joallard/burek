require 'config'
require 'yaml'
require 'core/burek_call'
require 'file_helpers'

module Burek

  module Core

    # Main method in burek. It works in three steps:
    #
    # 1. find all burek calls within folders specified in config
    # 2. add new translations to locales files
    # 3. replace all burek calls with regular translation calls
    #
    def self.run_burek
      Burek::FileHelpers.create_folder_if_missing Burek.config.get(:translations_path)

      puts "Searching for burek calls..."
      new_translations = Burek::Finder.find_burek_calls_in_files
      if new_translations.any?
        new_translations.each do |file, caption|
          puts "\t-> Found '#{caption}' in '#{file}'"
        end
      else
        puts "No burek calls found!"
      end
      
      puts "Adding translations to locale filess..."
      to_replace = Burek::LocalesCreator.create_locales(new_translations)
      
      puts "Repalcing burek calls with translation calls..."
      Burek::Replacer.replace_burek_calls_in_files(to_replace)

      puts "DONE!"
    end

    def self.add_to_translation_hash(locale, calls, translations_hash={})
      locale = locale.to_s # if it was symbol
      # Initialize hash for current locale
      translations_hash[locale] = {} unless translations_hash.has_key?(locale)

      calls.each do |call|
        cur_hash = translations_hash[locale]
        call.parent_key_array.each do |item|
          cur_hash[item] = {} unless cur_hash.has_key?(item)
          cur_hash = cur_hash[item]
        end
        cur_hash[call.key] = call.translation(locale)
      end

      return translations_hash
    end

    def self.fetch_params_from_string(string)
      string.scan(self.burek_call_params_regex).flatten
    end

    def self.burek_call_from_params_string(params)
      call = "BurekCall.new(#{params})"
      eval call
    end

    private

    # A regex for finiding burek calls
    def self.burek_call_params_regex
      /burek *\(([^\)]*)\)/
    end
    
  end
end
