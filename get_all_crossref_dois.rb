# coding: utf-8
require 'open-uri'
require 'json'
require 'cgi'

# Usage: $ ruby get_all_crossref_dois.rb
# Crossref REST API: http://api.crossref.org/

Api_uri_base = 'https://api.crossref.org'
Mode_base = '/works?'
Rows = 1000

hash_cursor = Hash.new(0)
cursor = '*'
cursor = CGI.escape(cursor)

def check_cursor(hash, next_cursor, api_uri)
  result_hash = Hash.new

  if hash.has_key?(next_cursor) == false
    hash[next_cursor] += 1
    result = false
  else
    hash[next_cursor] += 1
    result = true
  end

  result_hash['api_uri'] = api_uri
  result_hash['next_cursor'] = next_cursor
  result_hash['timestamp'] = Time.now

  if result == true
    result_hash['isLast'] = true
  else
    result_hash['isLast'] = false
  end

  File.open('api_uris.json', 'a'){|file|
    file.puts result_hash.to_json
    file.close
  }

  return result
end

num = 0
exit_flag = false

while exit_flag == false
  sleep 1.0
  file_num = format("%05d", num)
  outpath = "result_#{file_num}.json"

  api_uri = "#{Api_uri_base}#{Mode_base}rows=#{Rows}&cursor=#{cursor}"
  puts "#{file_num}\t#{api_uri}"

  File.open(outpath, 'w'){|file|
    begin
      content = open(api_uri).read
      hash = JSON.load(content)
      next_cursor = hash['message']['next-cursor']
    rescue
      retry
    end
    file.puts content
    file.close
    exit_flag = check_cursor(hash_cursor, next_cursor, api_uri)
    cursor = CGI.escape(next_cursor)
  }

  system("gzip #{outpath};")
  num += 1
end
