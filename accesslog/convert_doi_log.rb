# coding: utf-8
require 'zlib'
require 'time'
require 'cgi'
require 'json'

# 使い方: $ ruby convert_doi_log.rb (target_filepath: JaLC-access-log-YYMMDD-all.tsv.gz OR JST-access-log-YYMMDD-all.tsv.gz)

filepath = ARGV[0].to_s
outpath = filepath.dup
outpath.sub!('./', '')
outpath.sub!('.tsv.gz', '.json')
outpath = ".\/json\/#{outpath}"

hash_status_code = { "0"   => "RESERVED CODE - shouldn't happen!",
                     "1"   => "Success",
                     "2"   => "Error",
                     "100" => "Handle not found",
                     "200" => "Values not found",
                     "301" => "Server not responsible for handle"
                   }


def remove_dquote(line)
  if /^\"(.*?)\"$/ =~ line
    result = $1
  else
    result = line
  end
  return result
end

Zlib::GzipReader.open(filepath){|file|
  if /^(JaLC|JST)-access-log-(\d{6})-all\.tsv\.gz$/ =~ filepath # JaLC-access-log-YYMMDD-all.tsv.gz OR JST-access-log-YYMMDD-all.tsv.gz
    mode = $1
    yymm = $2
    target = "#{mode}_#{yymm}"
    case mode
    when 'JaLC' then
      ra = 'JaLC'
    when 'JST' then
      ra = 'Crossref'
    end
  else
    raise "Error::regexp:\t#{filepath}"
  end

  while line = file.gets
    hash = Hash.new
    line.chomp!
    line.scrub!('')


    if /^(.*?20\d{2}\d{2}.*?)\t(\d+\.\d+\.\d+\.\d+|\w+:\w+:\w+:\w+:\w+:\w+:\w+:\w+)\t(HTTP.*?:.*?)\t\"(.*?)\"\t(\d{1})\t(\d+)\t(\d+ms)\t(\"10\..*?\"|10\..*?)\t(\"200:0\.NA\/.*?\"|200:0\.NA\/.*?|.*?)\t(.*?)$/ =~ line
      server = $1
      ip = $2
      protocol = $3
      timestamp_raw = $4
      req_code = $5
      res_code = $6
      latency = $7
      doiname = $8
      handle = $9
      referer_raw = $10
    elsif /^(.*?20\d{2}\d{2}.*?-medra)\t(\d+\.\d+\.\d+\.\d+|\w+:\w+:\w+:\w+:\w+:\w+:\w+:\w+)\t(HTTP.*?:.*?)\t\"(.*?)\"\t(\d{1})\t(\d+)\t(\d+ms)\t(\"10\..*?\"|10\..*?)$/ =~ line
      server = $1
      ip = $2
      protocol = $3
      timestamp_raw = $4
      req_code = $5
      res_code = $6
      latency = $7
      doiname = $8
      handle = nil
      referer_raw = nil
    else
      p line
      raise "Error::regexp:\t#{line}"
    end


    doiname = remove_dquote(doiname) if doiname.nil? == false
    handle = remove_dquote(handle) if handle.nil? == false
    referer_raw = remove_dquote(referer_raw) if referer_raw.nil? == false

    timestamp_raw.gsub!("\t", ' ')
    timestamp = Time.parse(timestamp_raw)
    unixtime = timestamp.to_i

    timestamp_utc = timestamp.utc
    timestamp_jst = timestamp.getlocal
    year_utc = timestamp_utc.strftime('%Y')
    year_jst = timestamp_jst.strftime('%Y')
    month_utc = timestamp_utc.strftime('%m')
    month_jst = timestamp_jst.strftime('%m')
    day_utc = timestamp_utc.strftime('%d')
    day_jst = timestamp_jst.strftime('%d')
    yymm_utc = timestamp_utc.strftime('%Y-%m')
    yymm_jst = timestamp_jst.strftime('%Y-%m')
    yymmdd_utc = timestamp_utc.strftime('%Y-%m-%d')
    yymmdd_jst = timestamp_jst.strftime('%Y-%m-%d')
    req_result = hash_status_code[req_code]
    res_result = hash_status_code[res_code]

    if /^(.*?)\/(.*?)$/ =~ doiname
      doi_prefix = $1
    else
      doi_prefix = doiname
    end

    if doiname.nil? == true
      doiname_normalized = nil
    else
      doiname_normalized = CGI.unescape(doiname)
      doiname_normalized.gsub!("\n", '')
      doiname_normalized = doiname_normalized.downcase
    end

    if referer_raw.nil? == false
      if /^(.*?)\t*$/ =~ referer_raw
        referer_raw = $1
        referer = CGI.unescape(referer_raw)
        referer.gsub!("\n", '')
      end
    else
      referer = nil
    end


    hash['data'] = target
    hash['ra'] = ra
    hash['server'] = server
    hash['ip'] = ip
    hash['protocol'] = protocol
    hash['requested_code'] = req_code
    hash['requested_result'] = req_result
    hash['response_code'] = res_code
    hash['response_result'] = res_result
    hash['latency'] = latency
    hash['doiname'] = doiname
    hash['doiname_normalized'] = doiname_normalized
    hash['doi_prefix'] = doi_prefix
    hash['handle'] = handle
    hash['referer'] = referer
    hash['referer_raw'] = referer_raw
    hash['raw_timestamp'] = timestamp_raw
    hash['timestamp_unixtime'] = unixtime
    hash['timestamp_utc'] = timestamp_utc
    hash['timestamp_jst'] = timestamp_jst
    hash['timestamp_utc'] = timestamp_utc
    hash['timestamp_jst'] = timestamp_jst
    hash['year_utc'] = year_utc
    hash['month_utc'] = month_utc
    hash['day_utc'] = day_utc
    hash['year_jst'] = year_jst
    hash['month_jst'] = month_jst
    hash['day_jst'] = day_jst
    hash['yymm_utc'] = yymm_utc
    hash['yymm_jst'] = yymm_jst
    hash['yymmdd_utc'] = yymmdd_utc
    hash['yymmdd_jst'] = yymmdd_jst

    hash.each{|k,v|
      if v.class == String && v.length == 0
        hash[k] = nil
      end
    }

    File.open(outpath, 'a'){|outfile|
      begin
        outfile.puts hash.to_json
        puts hash.to_json
      rescue JSON::GeneratorError
        hash['referer'] = referer_raw
        outfile.puts hash.to_json
        puts hash.to_json
      end
    }

  end
  file.close
}
