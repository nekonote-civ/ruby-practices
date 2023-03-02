#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

# オプション未指定の場合は最大文字列長が固定
NO_OPTION_MAX_LENGTH = 7

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
  text.split(/[ \n\t]/).count { |element| !element.empty? }
end

# オプションを指定されているか？
def options_exists?(params)
  params[:l] || params[:w] || params[:c]
end

def all_counts_to_string(text)
  [
    get_return_count(text).to_s,
    get_words_count(text).to_s,
    text.bytesize.to_s
  ]
end

def exists_counts_to_string(text, params)
  [
    params[:l] ? get_return_count(text).to_s : '',
    params[:w] ? get_words_count(text).to_s : '',
    params[:c] ? text.bytesize.to_s : ''
  ].reject(&:empty?)
end

def main
  params = option_params

  if File.pipe?($stdin)
    read_line = $stdin.read
    if options_exists?(params)
      if params.length == 1
        results = exists_counts_to_string(read_line, params).join(' ')
        puts results
      else
        results = exists_counts_to_string(read_line, params)
        puts results.map { |result| result.rjust(NO_OPTION_MAX_LENGTH) }.join(' ')
      end
    else
      results = all_counts_to_string(read_line)
      puts results.map { |result| result.rjust(NO_OPTION_MAX_LENGTH) }.join(' ')
    end
  else
    file_name = ARGV[0]
    file_text = File.read(file_name)
    if options_exists?(params)
      if params.length == 1
        results = exists_counts_to_string(file_text, params).push(file_name).join(' ')
        puts results
      else
        results = exists_counts_to_string(file_text, params)
        max_length = results.map(&:length).max
        puts results.map { |result| result.rjust(max_length) }.push(file_name).join(' ')
      end
    else
      results = all_counts_to_string(file_text)
      max_length = results.map(&:length).max
      puts results.map { |result| result.rjust(max_length) }.push(file_name).join(' ')
    end
  end
end

main
