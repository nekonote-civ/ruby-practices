#!/usr/bin/env ruby

# frozen_string_literal: true

require 'optparse'

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

def in_params?(params)
  params[:l] || params[:w] || params[:c]
end

def main
  params = option_params
  file_name = ARGV[0]
  file_text = File.read(file_name)

  if in_params?(params)
    puts [
      params[:l] ? get_return_count(file_text).to_s : '',
      params[:w] ? get_words_count(file_text).to_s : '',
      params[:c] ? file_text.bytesize.to_s : ''
    ].reject(&:empty?).join(' ')
  else # no option
    results = [
      get_return_count(file_text).to_s,
      get_words_count(file_text).to_s,
      file_text.bytesize.to_s
    ]
    max_length = results.map(&:length).max
    results << file_name
    puts results.map { |result| result.rjust(max_length) }.join(' ')
  end
end

main
