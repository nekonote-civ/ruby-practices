#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

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
  counts = get_counts($stdin.read)
  length = single_option?(params) ? 0 : NO_OPTION_LENGTH
  puts join_counts(counts, length, params)
end

def print_type_file(params)
  counts_array = ARGV.map do |file_name|
    get_counts(File.read(file_name), file_name)
  end

  length = 0
  total_counts = sum_counts(counts_array)
  unless single_option?(params) && single_file?
    length = total_counts.map do |key, value|
      key != :file_name ? value : 0
    end.max.to_s.length
  end

  counts_array.each do |counts|
    puts join_counts(counts, length, params)
  end

  return if single_file?

  puts join_counts(total_counts, length, params)
end

def get_counts(text, file_name = '')
  {
    line: get_return_count(text),
    word: get_words_count(text),
    size: text.bytesize,
    file_name:
  }
end

def single_option?(params)
  params.length == 1
end

def single_file?
  ARGV.length == 1
end

def join_counts(counts, length, params)
  list = []
  list << counts[:line].to_s.rjust(length) if params[:l] || params.empty?
  list << counts[:word].to_s.rjust(length) if params[:w] || params.empty?
  list << counts[:size].to_s.rjust(length) if params[:c] || params.empty?
  list << counts[:file_name] unless counts[:file_name].to_s.empty?
  list.join(' ')
end

def get_return_count(text)
  text.scan(/\n/).length
end

def get_words_count(text)
  text.split(/[ \n\t]/).count { |t| !t.empty? }
end

def sum_counts(counts_array)
  total_counts = { line: 0, word: 0, size: 0, file_name: '合計' }
  counts_array.each do |counts|
    counts.each do |key, value|
      total_counts[key] += value if key != :file_name
    end
  end
  total_counts
end

main
