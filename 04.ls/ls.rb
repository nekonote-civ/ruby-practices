#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

NUMBER_OF_COLUMNS = 3
SINGLE_BYTE_CHAR_DISPLAY_LENGTH = 1
MULTI_BYTE_CHAR_DISPLAY_LENGTH = 2
OFFSET_SPACES = '  '

def translate_display_char_length(char)
  char.bytesize == 1 ? SINGLE_BYTE_CHAR_DISPLAY_LENGTH : MULTI_BYTE_CHAR_DISPLAY_LENGTH
end

def display_length(text)
  text.each_char.map { |char| translate_display_char_length(char) }.sum
end

def max_file_name_length(file_names)
  file_names.map { |file_name| display_length(file_name) }.max
end

def print_format_file_name(file_names_hash)
  spaces = ' ' * (file_names_hash[:max_length] - file_names_hash[:length])
  print "#{file_names_hash[:name]}#{spaces}#{OFFSET_SPACES}"
end

def search_files
  file_name = '*'
  folder_name = nil
  params = option_params

  # コマンドライン引数がオプションのみ以外の場合はファイル or ディレクトリの指定を行う
  unless ARGV.empty?
    argv = ARGV[0]
    if FileTest.directory?(argv)
      folder_name = argv
    else
      argv_array = argv.split('/')
      file_name = argv_array.pop
      folder_name = argv_array.join('/')
    end
  end

  # [-a] オプションが存在する場合は "." ファイルを含める
  flags = params[:a] ? File::FNM_DOTMATCH : 0
  Dir.glob(file_name, flags, base: folder_name)
end

def option_params
  opt = OptionParser.new
  params = {}
  opt.on('-a') { |v| params[:a] = v }
  opt.parse!(ARGV)
  params
end

def main
  files = search_files
  return if files.empty?

  row_count = files.length / NUMBER_OF_COLUMNS
  max_row = (files.length % NUMBER_OF_COLUMNS).zero? ? row_count : row_count + 1
  file_names_list = files.each_slice(max_row).to_a

  file_names_hash = file_names_list.map do |file_names|
    max_length = max_file_name_length(file_names)
    file_names.map do |name|
      length = display_length(name)
      { name:, length:, max_length: }
    end
  end

  max_row.times do |row|
    file_names_hash.length.times do |col|
      print_format_file_name(file_names_hash[col][row]) if file_names_hash[col][row]
    end
    puts
  end
end

main
