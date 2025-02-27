#!/usr/bin/env ruby

# frozen_string_literal: true

# 最大フレーム数
MAX_FRAMES = 10

# 特殊スコア(スペア or ストライク)
MAX_POINT = 10

# 最終フレームかどうか
def last_frame?(now_frame)
  now_frame == MAX_FRAMES - 1
end

# ストライクかどうか
def strike?(scores, cursor)
  scores[cursor] == MAX_POINT
end

# スペアかどうか
def spare?(scores, cursor)
  !strike?(scores, cursor) && scores[cursor] + scores[cursor + 1] == MAX_POINT
end

# スコアを引数から取得して配列化
argv = ARGV[0]
argv_splits = argv.split(',')

# スコアを数値化
scores = argv_splits.map do |score|
  score == 'X' ? MAX_POINT : score.to_i
end

point = 0 # スコアの合計値
cursor = 0 # 配列内の現在地

MAX_FRAMES.times do |frame|
  if last_frame?(frame)
    point += scores.slice(cursor, scores.size - cursor).sum
    break
  end

  if spare?(scores, cursor)
    point += (MAX_POINT + scores[cursor + 2])
    cursor += 2 # カーソル位置更新
  elsif strike?(scores, cursor)
    point += (MAX_POINT + scores[cursor + 1] + scores[cursor + 2])
    cursor += 1 # カーソル位置更新
  else
    point += (scores[cursor] + scores[cursor + 1])
    cursor += 2 # カーソル位置更新
  end
end

puts point
