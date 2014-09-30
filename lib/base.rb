#encoding: UTF-8

# in gems
require 'unicode_utils'
require 'nokogiri'

# system
require 'csv'
require 'pp'

# string processing

def clean t
  # line feed should be removed also
  !t ? '' : t.gsub("\n",' ').gsub("\t",' ').strip.gsub(/\s\s+/,' ')
end

def empty? t
  !t ? true : clean(t).gsub(' ','') == ''
end

def firstup s
  s[0]=UnicodeUtils.upcase(s[0]) if s!='' 
  return s
end

# serach hash return array

def hashfind a,k,v
  f = []
  a.each do |e|
    f << e if e[k]==v
  end
  f
end

def hashfindstart a,k,v
  f = []
  a.each do |e|
    f << e if e[k].start_with? v
  end
  f
end

def err file, s
  @errf.puts "file: #{file} - "+s
end

