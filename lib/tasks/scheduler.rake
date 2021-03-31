desc "This task is called by the Heroku scheduler add-on"
task :update_feed => :environment do
  require 'line/bot'  # gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  # line-bot側の設定
  # herokuにデプロイ後に、ENV["LINE_CHANNEL_SECRET"]、ENV["LINE_CHANNEL_TOKEN"]を登録する。
  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  # 使用したxmlデータ（毎日朝6時更新）：以下URLを入力すれば見ることができます。
  url  = "https://www.drk7.jp/weather/xml/13.xml"
  # xmlデータをパース（利用しやすいように整形）
  # url先の天気情報を文字列化→UTF-8に変換している
  xml  = open( url ).read.toutf8
  doc = REXML::Document.new(xml)
  # パスの共通部分を変数化（area[4]は「東京地方」を指定している）
  # ここ全国対応にしたい
  xpath = 'weatherforecast/pref/area[4]/info/rainfallchance/'
  # 6時〜24時の降水確率
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  # 降水確率20％以上のときがあったらメッセージが送られる
  min_per = 20
  if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
    word1 =
      ["ええ朝じゃね！",
       "よぉ寝れた？",
       "おはよう。体調はどんなかね？",
       "あのね、あのね、あのねのね。",
       "おはよう。ちぃとお寝坊さんかね？"].sample　# sampleメソッドで要素をランダムに取得
    word2 =
      ["気ぃつけて行ってきんさいよ！",
       "ええ１日を過ごそうや！",
       "雨に負けんこうぼちぼちやろうね。",
       "今日はカープの試合あるかねぇ。",
       "今日も楽しもうや！"].sample
    # 降水確率50％以上かどうかで追加メッセージ分岐させる
    mid_per = 50
    if per06to12.to_i >= mid_per || per12to18.to_i >= mid_per || per18to24.to_i >= mid_per
      word3 = "びっしゃこんなるけぇ傘持っていきんさいよ！"
    else
      word3 = "雨が降るかもしれんけぇ傘あったんが安心かもよ！"
    end
    # 発信するメッセージの設定
    push =
      "#{word1}\n#{word3}\n降水確率はこがな感じよ。よぉ見ときんさい。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word2}"
    # メッセージの発信先idを配列で渡す必要があるため、userテーブルよりpluck関数を使ってidを配列で取得
    user_ids = User.all.pluck(:line_id)
    message = {
      type: 'text',
      text: push
    }
    response = client.multicast(user_ids, message)
  end
  "OK"
end

