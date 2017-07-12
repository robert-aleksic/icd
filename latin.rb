#encoding: UTF-8

require_relative 'lib/base'

inme   = 'data/icd-en-me.csv'
inlat  = 'data/icd-latin.csv'
outme  = 'data/icd-en-me-lat.csv'
restlat = 'lat-rest.csv'
errfile = 'error.txt'


@infname = inlat

# empty error file
@errf = File.open errfile,'w'

puts 'reading latin from '+inlat
lat = {}
csvlatread inlat do |code, l|
  if l!='' and code[5]!='/' and code[6]!='/' #and code[0]!='V' and code[0]!='Y' and code[0]!='Z' 
    code = code[0..-2] if (code[-1]=='+') or (code[-1]=='*')
    lat[code] = l
  end
end

File.open outme, 'w' do |file| 

  me = []
  csvread inme do |num, code, kind, desc, contenten, contentme|

    s = [num,code,kind,desc,contenten,contentme].join("\t")
    if !lat[code] or (kind != 'preferred')
      l = ''
    else
      l = lat[code]
      lat.delete code
      s = s+"\t"+l
    end

    file.write (s+"\n")
  end
end

File.open restlat, 'w' do |file| 
  lat.each do |code, lat|
    file.write (code+"\t"+lat+"\n")
  end
end

#puts 'reading mne from '+inxml
#xml = nil
#File.open inxml do |f| 
#  xml = Nokogiri::XML f
#end

#puts 'substituting language'
#claml = xml.root
#i = 1
#laml.children.each do |c|
#  c.children.each do |ch| 
#    if ch.name == 'Rubric'
##      processrubric(i, ch,me[i])
#      i += 1
#      puts i if i % 5000 == 0
#    end
#  end
#end

#puts 'writing claml '+outxml
#File.open outxml, 'w' do |f|
#  f.write xml
#end


# empty error file
@errf.close
File.delete(errfile) if File.stat(errfile).size == 0
