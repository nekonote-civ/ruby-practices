#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'
require 'etc'

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

def search_files(params, argv)
  file_name = '*'
  folder_name = nil

  # コマンドライン引数がオプションのみ以外の場合はファイル or ディレクトリの指定を行う
  unless argv.empty?
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
  files = Dir.glob(file_name, flags, base: folder_name)

  # [-r] オプションが存在する場合は逆順にする
  params[:r] ? files.reverse : files
end

def option_params
  opt = OptionParser.new
  params = {}
  opt.on('-a') { |v| params[:a] = v }
  opt.on('-r') { |v| params[:r] = v }
  opt.on('-l') { |v| params[:l] = v }
  opt.parse!(ARGV)
  params
end

def convert_file_type(type)
  case type
  when 'file' then '-'
  when 'directory' then 'd'
  when 'characterSpecial' then 'c'
  when 'blockSpecial' then 'b'
  when 'fifo' then 'p'
  when 'link' then 'l'
  when 'socket' then 's'
  else ''
  end
end

def convert_file_permission(mode)
  case mode
  when '7' then 'rwx'
  when '6' then 'rw-'
  when '5' then 'r-x'
  when '4' then 'r--'
  when '3' then '-wx'
  when '2' then '-w-'
  when '1' then '--x'
  when '0' then '---'
  else ''
  end
end

def main
  params = option_params
  argv = ARGV.empty? ? '' : ARGV[0]
  files = search_files(params, argv)
  return if files.empty?

  # [-l] オプションが存在する場合は詳細情報付きで縦に表示する
  if params[:l]
    base_path = ''
    if !argv.empty? && FileTest.directory?(argv)
      base_path = +argv
      base_path << '/' if base_path[-1] != '/'
    end

    # 合計ブロック数
    total_blocks = 0

    # ファイルを順番に繰り返す
    files.each do |f|
      full_path = "#{base_path}#{f}"
      file_stat = File.lstat(full_path)
      total_blocks += file_stat.blocks

      file_attr = {}

      # ファイルのタイプ
      file_attr[:type] = convert_file_type(file_stat.ftype)

      # ファイルのパーミッション
      file_mode = file_stat.mode.to_s(8).slice(-3, 3)
      file_permission = file_mode.each_char.map { |mode| convert_file_permission(mode) }.join
      file_attr[:permission] = file_permission

      # ファイルのハードリンク
      file_attr[:hard_link] = file_stat.nlink

      # ファイルの所有者/グループ
      file_attr[:user] = Etc.getpwuid(file_stat.uid).name
      file_attr[:group] = Etc.getpwuid(file_stat.gid).name

      # ファイルサイズ
      file_attr[:size] = file_attr[:type] == 'c' || file_attr[:type] == 'b' ? "#{file_stat.rdev_major}, #{file_stat.rdev_minor}" : file_stat.size
    end
  else
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
end

main
