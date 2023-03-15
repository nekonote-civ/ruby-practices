#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

# オプション未指定の場合は最大文字列長が固定
NO_OPTION_LENGTH = 7

def main
  params = option_params
  File.pipe?($stdin) ? print_type_pipe(params) : print_type_file(params)
end

def option_params
  opt = OptionParser.new
  params = {}
  opt.on('-l') { |v| params[:l] = v }
  opt.on('-w') { |v| params[:w] = v }
  opt.on('-c') { |v| params[:c] = v }
  opt.parse!(ARGV)
  params
end

def print_type_pipe(params)
  counts = get_counts(params, $stdin.read)
  length = single_option?(params) ? 0 : NO_OPTION_LENGTH
  puts join_counts(counts, length)
end

def get_counts(params, text)
  params.empty? ? counts_all(text) : counts_some(text, params)
end

def single_option?(params)
  params.length == 1
end

def join_counts(counts, length)
  counts.map do |_key, value|
    value.to_s.rjust(length)
  end.join(' ')
end

def counts_all(text)
  {
    line: get_return_count(text),
    word: get_words_count(text),
    size: text.bytesize
  }
end

def counts_some(text, params)
  {
    line: params[:l] ? get_return_count(text) : 0,
    word: params[:w] ? get_words_count(text) : 0,
    size: params[:c] ? text.bytesize : 0
  }.reject { |_key, value| value.zero? }
end

def get_return_count(text)
  text.scan(/\n/).length
end

def get_words_count(text)
  text.split(/[ \n\t]/).count { |t| !t.empty? }
end

# 縦列毎の合計値の配列を作成
def total_counts(counts)
  Array.new(counts[0].length) { |col| Array.new(counts.length) { |row| counts[row][col] }.sum }
end

# [[a, b, c], [x, y, z]] のような2次元配列から表示文字列幅を算出
# 下記の様に オプションが1つ かつ 指定ファイルが1つ 以外の場合はここでカラム毎の幅が決定される
# 例) wc.rb -l test.txt
def column_print_length
  counts = ARGV.map do |file_name|
    file_text = File.read(file_name)
    counts_all(file_text)
  end
  counts << total_counts(counts)
  counts.map { |count| count.map { |count_item| count_item.to_s.length }.max }.max
end

# 0始まりの配列の最後に到達したか？
def last_array_index?(idx, array_length)
  idx == array_length - 1
end

def format_join_counts(is_last, join_counts, file_name)
  is_last ? "#{join_counts} 合計" : "#{join_counts} #{file_name}"
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
      puts format_join_counts(last_array_index?(idx, counts.length), join_counts, file_names[idx])
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
      puts format_join_counts(last_array_index?(idx, counts.length), join_counts, file_names[idx])
    end
  end
end

def print_type_file(params)
  counts = ARGV.map { |file_name| get_counts(params, File.read(file_name)) }
  params.length == 1 ? print_single_params(counts, ARGV) : print_multi_params(counts, ARGV)
end

# メイン処理実行
main
