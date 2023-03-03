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

def add_total_count(counts)
  total_counts = Array.new(counts[0].length) do |col|
    Array.new(counts.length) do |row|
      counts[row][col]
    end.sum
  end
  counts << total_counts
end

def print_type_file_length
  counts = ARGV.map do |file_name|
    file_text = File.read(file_name)
    all_counts(file_text)
  end
  counts = add_total_count(counts)
  counts.map { |count| count.map { |item| item.to_s.length }.max }.max
end

def print_type_file(params)
  length = print_type_file_length

  file_names = []
  counts = ARGV.map do |file_name|
    file_text = File.read(file_name)
    file_names << file_name
    get_counts(params, file_text)
  end

  if params.length == 1
    counts = counts.flatten(1)
    if file_names.length == 1
      puts "#{counts[0]} #{file_names[0]}"
    else
      counts << counts.sum
      counts.map.with_index do |count, idx|
        puts idx != counts.length - 1 ? "#{count.to_s.rjust(length)} #{file_names[idx]}" : "#{count.to_s.rjust(length)} 合計"
      end
    end
  else
    if file_names.length == 1
      counts.map.with_index do |count, idx|
        format_counts = join_counts(count, length)
        puts "#{format_counts} #{file_names[idx]}"
      end
    else
      counts = add_total_count(counts)
      counts.map.with_index do |count, idx|
        format_counts = join_counts(count, length)
        puts idx != counts.length - 1 ? "#{format_counts} #{file_names[idx]}" : "#{format_counts} 合計"
      end
    end
  end
end

def main
  params = option_params
  File.pipe?($stdin) ? print_type_pipe(params) : print_type_file(params)
end

main
