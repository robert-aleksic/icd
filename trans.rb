#encoding: UTF-8

require_relative 'lib/base'

fen = "data/icd-en.csv"
ftr = "data/icd-en-me-old.csv"
fme = "data/icd-en-me.csv"
ficd = "data/icd-o.csv"

puts 'reading translations and create hash from '+ftr
me = {}
csvread ftr do |num, code, kind, desc, contenten, contentme|
  if me[contenten] && me[contenten]!=contentme #&& me[contenten]!='' 
    puts
    puts "err #{num} #{code} #{kind} #{desc} #{contenten}"
    puts "  me[contenten]: #{me[contenten]}" 
    puts "  contentme:     #{contentme}"
    puts
  else
    me[contenten] = contentme
  end
end
puts "  #{me.length} strings read"
puts

puts "reading new english from #{fen} and create translations to #{fme}, and merging icd-o"

nold = 0
nnew = 0

i = 1
File.open fme, 'w' do |f|
  csvread fen do |num, code, kind, desc, contenten, contentme|
    
    if me[contenten]
      contentme = me[contenten]
      nold = nold+1
    else
      hashes = contenten.count('#')
      contentme = '!!!#'*hashes+'!!!'
      #contentme = contenten
      nnew = nnew+1
    end

    out = [i.to_s,code,kind,desc,contenten,contentme]
    f.write out.join("\t")+"\n"
    i = i+1
  end

  csvread ficd do |num, code, kind, desc, contenten, contentme|
    out = [i.to_s,code,kind,desc,contenten,contentme]
    f.write out.join("\t")+"\n"
    i = i+1
    nold = nold+1
  end

end
puts "  new translations: #{nnew}"
puts "  old translations: #{nold}"
