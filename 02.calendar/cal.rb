require "date"

# 引数が指定されていない場合
if ARGV.size == 0

  # 本日を取得(format: yyyy-m-d)
  today = Date.today

  # 現在の年月を取得
  year = today.year
  month = today.month

  # まずは現在の年月を表示する
  puts sprintf("%7d月 %d", month, year)

  # 曜日を出力
  puts "日 月 火 水 木 金 土"

  # 今月の最初 ~ 最後の日を求める
  month_first_day = 1
  month_last_day = Date.new(year, month, -1).day

  # wday(0=日, 1=月, 2=火, 3=水, 4=木, 5=金, 6=土)
  # 今月の1日の曜日
  this_month_first_day_of_week = Date.new(year, month, 1).wday

  # 日曜始まり以外の為に空白数を計算
  spaces = ""
  this_month_first_day_of_week.times { spaces += "   " }

  # 空白を出力
  print spaces

  # 改行用カウンタ(初期値は今月の1日の曜日)
  return_counter = this_month_first_day_of_week

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