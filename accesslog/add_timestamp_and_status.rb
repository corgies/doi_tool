# coding: utf-8
require 'json'
require 'zlib'
require 'time'

# つかいかた: $ ruby add_timestamp.rb 対象ファイルのpath (*.json.gz, 複数指定可)
# 概要: jsonデータにtimestamp および (request|response) code の結果 を追加する
# 出力データ: ./add_timestamp/*.json.gz

code_hash = Hash.new
code_hash = {"0" => "RESERVED CODE - shouldn't happen!", "1" => "Success", "2" => "Error",
             "100" => "Handle not found", "200" => "Values not found", "301" => "Server not responsible for handle"}

ARGV.each{|filepath|
  outpath = filepath.dup
  outpath.sub!('.gz', '')
  outpath.sub!('./', '')
  outpath = ".\/add_timestamp\/#{outpath}"

  puts filepath

  Zlib::GzipReader.open(filepath){|file|
    while line = file.gets
      line.chomp!

      hash = JSON.load(line)
      if hash.has_key?('timestamp_raw') == false
        if hash.has_key?('timestamp') == true
          timestamp_raw = hash['timestamp']
          hash['timestamp_raw'] = timestamp_raw
        else
          raise "Error::Timestamp not found:\t#{line}\t#{filepath}"
        end
      else
        timestamp_raw = hash['timestamp_raw']
      end
      hash.delete('timestamp')

      timestamp = Time.parse(timestamp_raw)
      unixtime_timestamp = timestamp.to_i

      hash['unixtime_timestamp'] = unixtime_timestamp
      hash['timestamp_utc'] = Time.at(unixtime_timestamp).utc
      hash['timestamp_jst'] = Time.at(unixtime_timestamp)

      request_code = hash['request_code']
      response_code = hash['response_code']
      hash['request_result'] = code_hash[request_code]
      hash['response_result'] = code_hash[response_code]

      File.open(outpath, 'a'){|outfile|
        puts hash.to_json
        outfile.puts hash.to_json
        outfile.close
      }
    end
    file.close
  }
  system("gzip --verbose #{outpath}")
}
