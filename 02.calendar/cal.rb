#!/usr/bin/env ruby

require "date"
require "optparse"

# 指定された年月のカレンダーを出力する
def show_cal(year, month, today)

  # 現在の年月を出力
  puts sprintf("%7d月 %d", month, year)

  # 曜日を出力
  puts "日 月 火 水 木 金 土"

  # 月初の空白を出力
  first_day_of_month = Date.new(year, month, 1)
  blanks = "   " * first_day_of_month.wday
  print blanks

  (first_day_of_month..Date.new(year, month, -1)).each do |day|

    # 日付を出力
    # 本日日付の場合は色を反転する
    print day == today ? sprintf("\e[30m\e[47m%2d\e[0m", day.day) : sprintf("%2d", day.day)
    
    # 土曜日のみ改行する
    print day.saturday? ? "\n" : " "
  end

  # 最後は改行を出力
  puts
end

# コマンドラインから受け取った引数の判定
opt = OptionParser.new

params = {}
opt.on('-y MANDATORY') { |v| params[:y] = v }
opt.on('-m MANDATORY') { |v| params[:m] = v }
opt.parse(ARGV)

# 本日日付を取得(format: yyyy-m-d)
today = Date.today

# コマンドライン引数を元に年月を指定
year = params[:y] ? params[:y].to_i : today.year.to_i
month = params[:m] ? params[:m].to_i : today.month.to_i

# カレンダー出力
show_cal(year, month, today)
