#encoding: UTF-8

# in gems
require 'unicode_utils' # for upper/lowercase conversion
require 'nokogiri'      # managing xml's

# system
require 'csv'
require 'pp'

# string processing

# clean new lines, tabs, spaces at beginning and end of line as well as multiple spaces
def clean t
  # line feed should be removed also
  !t ? '' : t.gsub("\n",' ').gsub("\t",' ').strip.gsub(/\s\s+/,' ')
end

# nil or just spaces inside after cleaning
def empty? t
  !t ? true : clean(t).gsub(' ','') == ''
end

# capitalize first letter
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

# read from translation and merge csv's 
def csvread (filename)
  File.readlines(filename).each do |line|
    if line && !empty?(line)
      num, code, kind, desc, contenten, contentme = line.split("\t")

      num = num
      code = clean(code)
      kind = clean(kind)
      contenten = clean(contenten)
      contentme = clean(contentme)

      yield num, code, kind, desc, contenten, contentme
    end
  end
end

# read from latin csv's 
def csvlatread (filename)
  File.readlines(filename).each do |line|
    if line && !empty?(line)
      f1, f2, code, lat, rest = line.split("\t")

      code = clean(code)
      lat  = clean(lat).downcase

      yield code, lat
    end
  end
end

# errors in translation
def haveerrors (desc, en, me)

  ena = en.split '#'
  mea = ((me+' ').split '#').map{|el|clean(el)}
  err = []
  
  if (mea == [] || mea == ['']) 
    err << 'nedostaje prevod' 
  else
    
    if ena.length != mea.length
      err << 'različita dužina' 
    else
      rasp = false
      ena.each_with_index do |e,i|
        m = mea[i]
        # puts [i,e,m].join(' ! ') # debug
        rasp = true if m==''
        if desc[i] == 'R'
          if m.length < 16 && m != e 
            err << e+' vs. '+m # different references
          end
        end
      end
      err << 'podela pomoću znaka #' if rasp
    end

  end

  return (err == []) ? '' : err.join('; ')

end