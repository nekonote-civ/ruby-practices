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
  {
    'file' => '-',
    'directory' => 'd',
    'characterSpecial' => 'c',
    'blockSpecial' => 'b',
    'fifo' => 'p',
    'link' => 'l',
    'socket' => 's'
  }[type]
end

def convert_access_permission(octal_mode)
  octal_mode.slice(-3, 3).each_char.map do |bit|
    {
      '7' => 'rwx',
      '6' => 'rw-',
      '5' => 'r-x',
      '4' => 'r--',
      '3' => '-wx',
      '2' => '-w-',
      '1' => '--x',
      '0' => '---'
    }[bit]
  end.join
end

def convert_special_permission(octal_mode, permission)
  special_permission_number = octal_mode[2].to_i
  is_sticky = special_permission_number & 1 != 0
  is_guid = special_permission_number & 2 != 0
  is_suid = special_permission_number & 4 != 0

  permission[2] = permission[2] == 'x' ? 's' : 'S' if is_suid
  permission[5] = permission[5] == 'x' ? 's' : 'S' if is_guid
  permission[-1] = permission[-1] == 'x' ? 't' : 'T' if is_sticky
  permission
end

def convert_permission(mode)
  octal_mode = mode.to_s(8).rjust(6, '0')
  permission = convert_access_permission(octal_mode)
  convert_special_permission(octal_mode, permission)
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

    total_blocks = 0

    # 項目別の最大文字列長
    max_length_list = {
      hard_link: 0,
      user: 0,
      group: 0,
      size: 0,
      major: 0,
      minor: 0,
      size_or_version: 0
    }

    file_attr_list = files.map do |file|
      full_path = "#{base_path}#{file}"
      file_stat = File.lstat(full_path)
      total_blocks += file_stat.blocks

      file_attr = {}

      # ファイルのタイプ
      file_attr[:type] = convert_file_type(file_stat.ftype)

      # ファイルのパーミッション
      file_attr[:permission] = convert_permission(file_stat.mode)

      # ファイルのハードリンク
      file_attr[:hard_link] = file_stat.nlink.to_s
      max_length_list[:hard_link] = max_length_list[:hard_link] > file_attr[:hard_link].length ? max_length_list[:hard_link] : file_attr[:hard_link].length

      # ファイルの所有者/グループ
      user_name = Etc.getpwuid(file_stat.uid).name
      file_attr[:user] = user_name
      max_length_list[:user] = max_length_list[:user] > file_attr[:user].length ? max_length_list[:user] : file_attr[:user].length

      group_name = Etc.getpwuid(file_stat.gid).name
      file_attr[:group] = group_name
      max_length_list[:group] = max_length_list[:group] > file_attr[:group].length ? max_length_list[:group] : file_attr[:group].length

      # ファイルサイズ or メジャー/マイナー番号
      if %w[b c].include?(file_attr[:type])
        file_attr[:major] = file_stat.rdev_major.to_s
        file_attr[:minor] = file_stat.rdev_minor.to_s
        max_length_list[:major] = max_length_list[:major] > file_attr[:major].length ? max_length_list[:major] : file_attr[:major].length
        max_length_list[:minor] = max_length_list[:minor] > file_attr[:minor].length ? max_length_list[:minor] : file_attr[:minor].length
      else
        file_attr[:size] = file_stat.size.to_s
        max_length_list[:size] = max_length_list[:size] > file_attr[:size].length ? max_length_list[:size] : file_attr[:size].length
      end

      # 更新日時
      mtime = file_stat.mtime
      file_attr[:mtime] = format('%2<month>d月 %2<day>d %02<hour>d:%02<min>d', month: mtime.month, day: mtime.day, hour: mtime.hour, min: mtime.min)

      # ファイル名
      file_attr[:name] = file_stat.symlink? ? "#{file} -> #{File.readlink(full_path)}" : file

      file_attr
    end

    # メジャー/マイナー番号の場合は " ," で連結されるため +2 のオフセットを行う
    max_length_list[:size_or_version] = [max_length_list[:size], max_length_list[:major] + max_length_list[:minor] + 2].max

    # stat と ls の扱うブロック数が異なるため補正
    puts "合計 #{total_blocks / 2}"

    file_attr_list.each do |file|
      format_file_name = +"#{file[:type]}#{file[:permission]}"
      format_file_name << " #{file[:hard_link].rjust(max_length_list[:hard_link])}"
      format_file_name << " #{file[:user].ljust(max_length_list[:user])} #{file[:group].ljust(max_length_list[:group])}"
      format_file_name << if file[:size]
                            " #{file[:size].rjust(max_length_list[:size_or_version])}"
                          else
                            " #{file[:major].rjust(max_length_list[:major])}, #{file[:minor].rjust(max_length_list[:minor])}"
                          end
      format_file_name << " #{file[:mtime]}"
      format_file_name << " #{file[:name]}"
      puts format_file_name
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
