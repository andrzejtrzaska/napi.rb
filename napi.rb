#!/usr/bin/env ruby

require 'digest'
require 'net/http'

def md5(path)
  Digest::MD5.hexdigest(File.open(path).read(10_485_760))
end

def f(md5sum)
  t_idx = [0xe, 0x3, 0x6, 0x8, 0x2]
  t_mul = [2, 2, 5, 4, 3]
  t_add = [0, 0xd, 0x10, 0xb, 0x5]
  b = ''

  (0..4).each do |i|
    a = t_add[i]
    m = t_mul[i]
    g = t_idx[i]
    t = a + md5sum[g].to_i(16)
    v = md5sum[t..t + 1].to_i(16)
    x = v * m % 0x10
    z = x.to_s(16)
    b += z
  end
  b
end

ALLOWED_EXTENSIONS = %w(avi mp4 mkv mov webm flv rmvb mpg mpeg 3gp).freeze

def find_subtitles(path)
  extension = File.extname(path).delete('.')
  unless ALLOWED_EXTENSIONS.include?(extension)
    puts "Format #{extension} is not supported"
    return
  end

  md5sum = md5(path)
  f_param = md5sum
  t_param = f(md5sum)
  url = "http://napiprojekt.pl/unit_napisy/dl.php?l=PL&f=#{f_param}"\
    "&t=#{t_param}&v=pynapi&kolejka=false&nick=&pass=&napios=posix"
  response = Net::HTTP.get(URI(url))
  dir = File.dirname(path)
  base = File.basename(path, '.*')
  extension = '.txt'
  out_path = "#{dir}/#{base}#{extension}"
  body = begin
           response.dup.force_encoding('windows-1250').encode('utf-8')
         rescue Encoding::UndefinedConversionError
           response.dup
         end

  if body.lines.count > 3
    File.write(out_path, body)
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
