# frozen_string_literal: true

require "json"

prefs = JSON.parse(File.read("data/prefectures.json"))
prefs.each do |pref|
  code = pref["code"]
  file = format("data/cities/%02d.json", code)
  cities = JSON.parse(File.read(file))
  capital = cities.find { |c| c["capital"] }
  next unless capital
  next if capital["code"] == pref["capital_code"]

  puts "#{code} #{pref["name"]}: JSON=#{pref["capital_code"]} 実際=#{capital["code"]} #{capital["name"]}"
end
puts "検証完了"
