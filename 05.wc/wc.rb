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
  str = File.read(ARGV[0])

  if in_params?(params)
    puts [
      params[:l] ? get_return_count(str).to_s : '',
      params[:w] ? get_words_count(str).to_s : '',
      params[:c] ? str.bytesize.to_s : ''
    ].reject(&:empty?).join(' ')
  else
    puts [
      get_return_count(str),
      get_words_count(str),
      str.bytesize
    ].join(' ')
  end
end

main
