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

def print_type_file(params)
  counts_array = ARGV.map do |file_name|
    get_counts(params, File.read(file_name))
  end

  # オプション数1 かつ ファイル数1 のパターン以外の場合は文字列幅が設定される
  length = 0
  unless single_option?(params) && single_file?
    total_counts = sum_counts(counts_array, params)
    length = total_counts.values.map { |value| value.to_s.length }.max
  end

  # 各カラムの値を出力
  counts_array.each_with_index do |counts, idx|
    puts "#{join_counts(counts, length)} #{ARGV[idx]}"
  end

  return if single_file?

  # 合計値を出力
  total_counts = sum_counts(counts_array, params)
  puts "#{join_counts(total_counts, length)} 合計"
end

def get_counts(params, text)
  counts = {}
  counts[:line] = get_return_count(text) if params[:l] || params.empty?
  counts[:word] = get_words_count(text) if params[:w] || params.empty?
  counts[:size] = text.bytesize if params[:c] || params.empty?
  counts
end

def single_option?(params)
  params.length == 1
end

def single_file?
  ARGV.length == 1
end

def join_counts(counts, length)
  counts.values.map do |value|
    value.to_s.rjust(length)
  end.join(' ')
end

def get_return_count(text)
  text.scan(/\n/).length
end

def get_words_count(text)
  text.split(/[ \n\t]/).count { |t| !t.empty? }
end

def sum_counts(counts_array, params)
  total_counts = init_total_counts(params)
  counts_array.each do |counts|
    counts.each do |key, value|
      total_counts[key] += value if total_counts[key]
    end
  end
  total_counts
end

def init_total_counts(params)
  total_counts = {}
  total_counts[:line] = 0 if params[:l] || params.empty?
  total_counts[:word] = 0 if params[:w] || params.empty?
  total_counts[:size] = 0 if params[:c] || params.empty?
  total_counts
end

# メイン処理実行
main
