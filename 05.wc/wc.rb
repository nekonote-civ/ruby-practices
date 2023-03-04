#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

# オプション未指定の場合は最大文字列長が固定
NO_OPTION_LENGTH = 7

def option_params
  opt = OptionParser.new
  params = {}
  opt.on('-l') { |v| params[:l] = v }
  opt.on('-w') { |v| params[:w] = v }
  opt.on('-c') { |v| params[:c] = v }
  opt.parse!(ARGV)
  params
end

def get_return_count(text)
  text.scan(/\n/).length
end

def get_words_count(text)
  text.split(/[ \n\t]/).count { |t| !t.empty? }
end

def all_counts(text)
  [
    get_return_count(text),
    get_words_count(text),
    text.bytesize
  ]
end

def some_counts(text, params)
  [
    params[:l] ? get_return_count(text) : 0,
    params[:w] ? get_words_count(text) : 0,
    params[:c] ? text.bytesize : 0
  ].reject(&:zero?)
end

def get_counts(params, text)
  params.empty? ? all_counts(text) : some_counts(text, params)
end

def join_counts(counts, length)
  counts.map { |count| count.to_s.rjust(length) }.join(' ')
end

def print_type_pipe(params)
  pipe_text = $stdin.read
  counts = get_counts(params, pipe_text)
  puts params.length == 1 ? counts[0] : join_counts(counts, NO_OPTION_LENGTH)
end

# 縦列毎の合計値の配列を作成
def total_counts(counts)
  Array.new(counts[0].length) { |col| Array.new(counts.length) { |row| counts[row][col] }.sum }
end

# [[a, b, c], [x, y, z]] のような2次元配列から表示文字列幅を算出
# オプションが1つ、指定ファイルも1つ以外の場合はこの値でカラム毎の幅が決定される
def column_print_length
  counts = ARGV.map do |file_name|
    file_text = File.read(file_name)
    all_counts(file_text)
  end
  counts << total_counts(counts)
  counts.map { |count| count.map { |count_item| count_item.to_s.length }.max }.max
end

def format_join_counts(idx, counts_length, join_counts, file_name)
  idx != counts_length - 1 ? "#{join_counts} #{file_name}" : "#{join_counts} 合計"
end

def print_single_params(counts, file_names)
  counts = counts.flatten(1)
  if file_names.length == 1
    puts "#{counts[0]} #{file_names[0]}"
  else
    counts << counts.sum
    length = column_print_length
    counts.each_with_index do |count, idx|
      join_counts = count.to_s.rjust(length)
      puts format_join_counts(idx, counts.length, join_counts, file_names[idx])
    end
  end
end

def print_multi_params(counts, file_names)
  length = column_print_length
  if file_names.length == 1
    counts.each_with_index do |count, idx|
      join_counts = join_counts(count, length)
      puts "#{join_counts} #{file_names[idx]}"
    end
  else
    counts << total_counts(counts)
    counts.each_with_index do |count, idx|
      join_counts = join_counts(count, length)
      puts format_join_counts(idx, counts.length, join_counts, file_names[idx])
    end
  end
end

def print_type_file(params)
  counts = ARGV.map do |file_name|
    file_text = File.read(file_name)
    get_counts(params, file_text)
  end

  file_names = ARGV
  params.length == 1 ? print_single_params(counts, file_names) : print_multi_params(counts, file_names)
end

def main
  params = option_params
  File.pipe?($stdin) ? print_type_pipe(params) : print_type_file(params)
end

main
