#!/usr/bin/env ruby

require "date"
require "optparse"

# 指定された年月のカレンダーを出力する
def show_cal(year, month)

  # 現在の年月を出力
  puts sprintf("%7d月 %d", month, year)

  # 曜日を出力
  puts "日 月 火 水 木 金 土"

  # 今月の最初と最後の日を求める
  month_first_day = 1
  month_last_day = Date.new(year, month, -1).day

  # wday(0=日, 1=月, 2=火, 3=水, 4=木, 5=金, 6=土)
  # 今月の1日の曜日を求める
  month_first_day_of_week = Date.new(year, month, 1).wday

  # 日曜始まり以外の為に空白数を求める
  blanks = ""
  month_first_day_of_week.times { blanks += "   " }

  # 空白を出力
  print blanks

  # 改行用カウンタ
  return_counter = month_first_day_of_week

  # 今月の日付を順番に出力
  month_first_day.upto(month_last_day) { |x|

    # 日付を出力
    print sprintf("%2d", x)

    # 土曜日の場合は改行してカウンタを初期化
    if return_counter >= 6
      print "\n"
      return_counter = 0
    else
      # 空白を出力してカウンタを更新
      print " "
      return_counter += 1
    end
  }
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
show_cal(year, month)