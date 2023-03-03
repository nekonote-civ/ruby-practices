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
    get_return_count(text).to_s,
    get_words_count(text).to_s,
    text.bytesize.to_s
  ]
end

def some_counts(text, params)
  [
    params[:l] ? get_return_count(text).to_s : '',
    params[:w] ? get_words_count(text).to_s : '',
    params[:c] ? text.bytesize.to_s : ''
  ].reject(&:empty?)
end

def get_counts(params, text)
  params.empty? ? all_counts(text) : some_counts(text, params)
end

def join_counts(counts, length)
  counts.map { |count| count.rjust(length) }.join(' ')
end

def print_counts(params, counts, length, file_name = '')
  format = params.length == 1 ? counts[0] : join_counts(counts, length)
  puts file_name.empty? ? format : "#{format} #{file_name}"
end

def print_type_pipe(params)
  pipe_text = $stdin.read
  counts = get_counts(params, pipe_text)
  print_counts(params, counts, NO_OPTION_LENGTH)
end

def print_type_directory(params)
  file_name = ARGV[0]
  file_text = File.read(file_name)
  counts = get_counts(params, file_text)
  print_length = counts.map(&:length).max
  print_counts(params, counts, print_length, file_name)
end

def main
  params = option_params
  File.pipe?($stdin) ? print_type_pipe(params) : print_type_directory(params)
end

main
