# coding: utf-8
require 'zlib'
require 'json'
require 'fileutils'
require 'cgi'

# つかいかた: $ ruby convert_doi_log_jst.rb 対象ファイルのpath (*.tsv.gz, 複数指定可)
# 出力データ: ./json/*.json.gz

# 初期化
def remove_file(filepath)
  if File.exist?(filepath) == true
    FileUtils.rm(filepath)
  end

  if File.exist?("#{filepath}.gz") == true
    FileUtils.rm("#{filepath}.gz")
  end
end

def save_file(filepath, line)
  File.open(filepath, 'a'){|file|
    file.puts line
    file.close
  }
end

ARGV.each{|filepath|
  outpath = filepath.dup
  outpath.gsub!('./', '')
  outpath = outpath.sub!('.tsv.gz', '')
  outpath_json = ".\/json\/#{outpath}.json"

  remove_file(outpath_json)

  Zlib::GzipReader.open(filepath){|file|
    while line = file.gets
      line.chomp!
      line.scrub!('') # REMOVE 'invalid byte sequence in UTF-8'

      hash = Hash.new

      if /^(.*?)\t([\d|\.]+|[\w|:]+)\t(.*?)\t\"(\d{4}-\d{2}-\d{2}\t.*?)\"\t(\d+)\t(\d+)\t(.*?ms)\t(.*?)\t\"(.*?)\"\t\"(.*?)\"$/ =~ line
        server = $1
        ip = $2
        protocol = $3
        timestamp_raw = $4
        request_code = $5
        response_code = $6
        latency = $7
        doiname = $8
        handle = $9
        referer = $10
      elsif /^(.*?-medra)\t([\d|\.]+|[\w|:]+)\t(.*?)\t\"(\d{4}-\d{2}-\d{2}\t.*?)\"\t(\d+)\t(\d+)\t(.*?ms)\t(.*?)$/ =~ line
        server = $1
        ip = $2
        protocol = $3
        timestamp_raw = $4
        request_code = $5
        response_code = $6
        latency = $7
        doiname = $8
        handle = nil
        referer = nil
      else
        raise "Error::regexp:\t#{filepath}\t#{line}"
      end

      if /^(.*?)\t$/ =~ referer
        referer = $1
      end

      referer = nil if referer.nil? == false && referer.length == 0
      referer_raw = referer

      if referer.nil? == false
        referer = CGI.unescape(referer)
        referer.gsub!("\n", '')
      end

      timestamp_raw.gsub!("\t", ' ')

      hash['server'] = server
      hash['ip'] = ip
      hash['protocol'] = protocol
      hash['timestamp_raw'] = timestamp_raw
      hash['request_code'] = request_code
      hash['response_code'] = response_code
      hash['latency'] = latency
      hash['doiname'] = doiname
      hash['handle'] = handle
      hash['referer'] = referer
      hash['referer_raw'] = referer_raw

      begin
        hash.to_json
      rescue JSON::GeneratorError
        hash['referer'] = referer_raw
        hash.to_json
      end

      save_file(outpath_json, hash.to_json)
      linum += 1

    end
    file.close
    system("gzip --verbose #{outpath_json}")
  }
}
