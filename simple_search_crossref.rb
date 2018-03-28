# coding: utf-8
require 'cgi'
require 'open-uri'
require 'json'
require 'optparse'

# Document about Crossref REST API is here => https://api.crossref.org/
# Help:  $ ruby simple_search_crossref.rb -h
## sample1  $ ruby simple_search_crossref.rb --query 'Communication design for electronic negotiations on the basis of XML schema'
## sample2  $ ruby simple_search_crossref.rb --doi 10.1145/371920.371924

def add_to_hash(original_hash, save_hash, key)
  if original_hash.has_key?(key) == true
    fixed_key = key.downcase
    fixed_key.gsub!('-', '_')

    if original_hash[key].class == Array && original_hash[key].length == 1
      save_hash[fixed_key] = original_hash[key].join('')
    else
      save_hash[fixed_key] = original_hash[key]
    end
  else
  end
  return save_hash
end

def make_result_hash(original_hash, result_hash)
  result_hash = add_to_hash(original_hash, result_hash, 'type')
  result_hash = add_to_hash(original_hash, result_hash, 'DOI')
  result_hash = add_to_hash(original_hash, result_hash, 'title')
  result_hash = add_to_hash(original_hash, result_hash, 'author')
  result_hash = add_to_hash(original_hash, result_hash, 'acronym')
  result_hash = add_to_hash(original_hash, result_hash, 'page')
  result_hash = add_to_hash(original_hash, result_hash, 'container-title')
  result_hash = add_to_hash(original_hash, result_hash, 'publisher')
  result_hash = add_to_hash(original_hash, result_hash, 'number')
  return result_hash
end

def get_api(uri)
  content = JSON.load(open(uri).read)
  if content['status'] == 'ok'
    if content['message'].has_key?('items') == true
      content['message']['items'].each{|original_hash|
        result_hash = Hash.new
        result_hash = make_result_hash(original_hash, result_hash)
        result_hash.each{|k,v|
          puts "#{k}:\t#{v}"
        }
        puts ''
      }
    else
      original_hash = content['message']
      result_hash = Hash.new
      result_hash = make_result_hash(original_hash, result_hash)
      puts result_hash.to_json
    end
  else
    raise "Error::unknown class?\t#{content['message'].class}\t#{content}"
  end
end

def params_validation(params)
  if params['query'].nil? == true && params['doi'].nil? == true
    puts "Error:: See Usage: $ ruby #{$0} -h"
    exit
  end

  puts "Your Input: #{params}"
  
  if params['doi'].nil? == false
    doi = params['doi']
    if /^10\.\d+\/.*?$/ =~ doi
    elsif /^.*?(10\.\d+\/.*?)$/ =~ doi
      params['doi'] = $1
      params['query'] = nil
    else
      puts "Reset Invalid DOI name -> nil"
      params['doi'] = nil
    end
  else
  end

  if params['n'].nil? ==false
    n = params['n'].to_i
    if 0 < n && n <= 1000
      # OK
    else
      puts "Reset -> n: 50 (default)"
      params['n'] = 50
    end
  end

  puts "Fixed Input: #{params}"
  return params
end

######### MAIN ############
sort_mode = 'relevance' # 'score' or 'relevance'

params = ARGV.getopts('', 'query:', 'doi:', 'n:50')
params = params_validation(params)

if params['doi'].nil? == false
  doi = params['doi']
  search_mode = 'doi'
elsif params['query'].nil? == false
  query = params['query']
  search_mode = 'query'
else
  raise "Error::Try again\t#{params}"
end

rows = params['n']

case search_mode
when 'doi' then
  api_uri = 'https://api.crossref.org/works/' + doi
when 'query' then
  api_uri = 'https://api.crossref.org/works/?' + "sort=#{sort_mode}&rows=#{rows}&query=#{CGI.escape(query)}"
else
  raise "Error"
end

puts "**Result**"
get_api(api_uri)
