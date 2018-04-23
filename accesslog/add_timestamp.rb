# coding: utf-8
require 'json'
require 'zlib'
require 'time'

# つかいかた: $ ruby add_timestamp.rb 対象ファイルのpath (*.json.gz, 複数指定可)
# 出力データ: ./add_timestamp/*.json.gz

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
