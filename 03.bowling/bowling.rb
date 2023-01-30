# frozen_string_literal: true

# 最大フレーム数
MAX_FRAMES = 10

# 特殊スコア
POINT_SPARE  = 10 # スペア
POINT_STRIKE = 10 # ストライク

# 最終フレームかどうか
def last_frame?(now_frame)
  now_frame == MAX_FRAMES - 1
end

# ストライクかどうか
def strike?(num_scores, cursor)
  num_scores[cursor] == POINT_STRIKE
end

# スペアかどうか
def spare?(num_scores, cursor)
  !strike?(num_scores, cursor) && num_scores[cursor] + num_scores[cursor + 1] == POINT_SPARE
end

# スコアを引数から取得して配列化
score = ARGV[0]
scores = score.split(',')

# スコアを数値化
num_scores = scores.map { |score|
  if score == 'X'
    POINT_STRIKE 
  else
    score.to_i
  end
}

point     = 0 # スコアの合計値
cursor    = 0 # 配列内の現在地
now_frame = 0 # 現在のフレーム数

while now_frame <= MAX_FRAMES - 1

  if last_frame?(now_frame)
    point += num_scores.
      slice(cursor, num_scores.size - cursor)
      .sum
    break
  end

  if spare?(num_scores, cursor)
    point += (POINT_SPARE + num_scores[cursor + 2])
    cursor += 2 # カーソル位置更新
  elsif strike?(num_scores, cursor)
    point += (POINT_STRIKE + num_scores[cursor + 1] + num_scores[cursor + 2])
    cursor += 1 # カーソル位置更新
  else
    point += (num_scores[cursor] + num_scores[cursor + 1])
    cursor += 2 # カーソル位置更新
  end

  now_frame += 1
end

puts point
