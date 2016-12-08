#!/usr/bin/env ruby

require 'digest'
require 'net/http'
require 'base64'
require 'fileutils'

API_VERSION = ENV.fetch('NAPIPROJEKT_API_VERSION', 1)
ARCHIVE_PASSWORD = 'iBlm8NTigvru0Jr0'.freeze
ALLOWED_EXTENSIONS = %w(avi mp4 mkv mov webm flv rmvb mpg mpeg 3gp).freeze
TEN_MEGABYTES = 10_485_760
T_IDX = [0xe, 0x3, 0x6, 0x8, 0x2].freeze
T_MUL = [2, 2, 5, 4, 3].freeze
T_ADD = [0, 0xd, 0x10, 0xb, 0x5].freeze
DEFAULT_ENCODING = 'windows-1250'.freeze

def download_method_name
  "download_v#{API_VERSION}"
end

def save_method_name
  "save_v#{API_VERSION}"
end

def md5(path)
  Digest::MD5.hexdigest(File.open(path).read(TEN_MEGABYTES))
end

def f(md5sum)
  b = ''

  (0..4).each do |i|
    a = T_ADD[i]
    m = T_IDX[i]
    g = T_IDX[i]
    t = a + md5sum[g].to_i(16)
    v = md5sum[t..t + 1].to_i(16)
    x = v * m % 0x10
    z = x.to_s(16)
    b += z
  end
  b.downcase
end

def download_v1(md5sum)
  response = get_response_v1(md5sum)
  process_response_v1(response)
end

def get_response_v1(md5sum)
  f_param = md5sum
  t_param = f(md5sum)
  url = "http://napiprojekt.pl/unit_napisy/dl.php?l=PL&f=#{f_param}"\
    "&t=#{t_param}&v=pynapi&kolejka=false&nick=&pass=&napios=posix"
  Net::HTTP.get(URI(url))
end

def process_response_v1(response_body)
  return if response_body.lines.count < 5
  response_body.dup.force_encoding(DEFAULT_ENCODING).encode('utf-8')
rescue Encoding::UndefinedConversionError
  response_body.dup
end

def save_v1(dir, base, response)
  sub_path = "#{dir}/#{base}.txt"
  File.write(sub_path, response)
end

def download_v3(md5sum)
  response = get_response_v3(md5sum)
  process_response_v3(response)
end

def get_response_v3(md5sum)
  form = {
    mode: 31,
    client: 'NapiProjektPython',
    client_ver: '2.2.0.2399',
    user_nick: '',
    user_password: '',
    downloaded_subtitles_id: md5sum,
    downloaded_subtitles_lang: 'PL',
    downloaded_cover_id: md5sum,
    advert_type: 'flashAllowed',
    video_info_hash: md5sum,
    nazwa_pliku: 'example.mp4',
    rozmiar_pliku_bajty: 1024,
    the: 'end'
  }
  url = 'http://napiprojekt.pl/api/api-napiprojekt3.php'
  Net::HTTP.post_form(URI(url), form).body
end

def process_response_v3(response_body)
  regex = /<content><!\[CDATA\[(?<subtitles>.+)\]\]><\/content>/
  match = response_body.match(regex)
  return unless match
  encoded_subs = match[:subtitles]
  Base64.decode64(encoded_subs)
end

def save_v3(dir, base, response)
  zip_path = "#{dir}/#{base}.7z"
  sub_path = "#{dir}/#{base}.txt"
  File.write(zip_path, response)
  extract_7z(zip_path, sub_path)
  FileUtils.rm(zip_path)
end

def extract_7z(zip_path, sub_path)
  cmd = "7z x -y -so -p\"#{ARCHIVE_PASSWORD}\" \"#{zip_path}\" 2> /dev/null > \"#{sub_path}\""
  system cmd
end

def find_subtitles(path)
  extension = File.extname(path).delete('.')
  unless ALLOWED_EXTENSIONS.include?(extension)
    puts "Format #{extension} is not supported"
    return
  end

  md5sum = md5(path)
  response = send(download_method_name, md5sum)
  if response
    dir = File.dirname(path)
    base = File.basename(path, '.*')
    send(save_method_name, dir, base, response)
    puts "Subtitles found for #{path}"
  else
    puts "No subtitles found for #{path}"
  end
end

def find_subtitles_folder(path)
  count = 0
  entries = Dir["#{path}/**/*"]
  entries.each do |entry|
    extension = File.extname(entry).delete('.')
    next unless ALLOWED_EXTENSIONS.include?(extension)
    find_subtitles(entry)
    count += 1
  end

  puts "Found #{count} subtitles"
end

path = ARGV[0]
if File.directory?(path)
  find_subtitles_folder(path)
elsif File.file?(path)
  find_subtitles(path)
end
