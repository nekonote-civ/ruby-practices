#!/usr/bin/env ruby

require "date"
require "optparse"

# 指定された年月のカレンダーを出力する
def show_cal(year, month, today)

  # 現在の年月を出力
  puts sprintf("%7d月 %d", month, year)

  # 曜日を出力
  puts "日 月 火 水 木 金 土"

  (Date.new(year, month, 1)..Date.new(year, month, -1)).each do |day|
    
    # 日曜始まり以外の為に空白数を求める
    if day.day == 1
      blanks = ""
      day.wday.times { blanks += "   " } 
      print blanks
    end

    # 日付を出力
    # 本日日付の場合は色を反転する
    print day === today ? sprintf("\e[30m\e[47m%2d\e[0m", day.day) : sprintf("%2d", day.day)
    
    # 土曜日のみ改行する
    print day.saturday? ? "\n" : " "
  end
end

# コマンドラインから受け取った引数の判定
opt = OptionParser.new

params = {}
opt.on('-y') { |v| params[:y] = v }
opt.on('-m') { |v| params[:m] = v }

# 不正な引数の例外処理
begin
  opt.parse(ARGV)
rescue OptionParser::InvalidOption => e
  puts "#{e.message}"
  puts "引数には [-y] [-m] のいずれかを指定してください。"
  exit
end

# 本日日付を取得(format: yyyy-m-d)
today = Date.today

# -y と -m が設定されている場合、順不同でも正しい変数へ設定出来るようにする
if params[:y] && params[:m]
  opt1 = ARGV[0]

  if opt1 == "-y"
    year = ARGV[1].to_i
    month = ARGV[3].to_i
  else
    year = ARGV[3].to_i
    month = ARGV[1].to_i
  end
# -y だけのパターン
elsif params[:y]
  # 年月を設定
  year = ARGV[1].to_i
  month = today.month.to_i
# -m だけのパターン
elsif params[:m]
  # 年月を設定
  year = today.year.to_i
  month = ARGV[1].to_i
# 引数なし
else
  # 年月を設定
  year = today.year.to_i
  month = today.month.to_i
end

# カレンダー出力
show_cal(year, month, today)
