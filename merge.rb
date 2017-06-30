#encoding: UTF-8

require_relative 'lib/base'

infile       = 'data/icd-en-me.csv'
tmpinfile    = 't1.csv'
mergefile    = 'icd-merge.csv'
tmpmergefile = 't2.csv'


puts 'reading rubrics from '+infile
rubrics = []
csvread infile do |num, code, kind, desc, contenten, contentme|
  rubrics[num.to_i] = {code: code, kind: kind, desc: desc, contenten: contenten, contentme:contentme}
end

puts 'merging and writing errors into '+tmpmergefile

count = {}
File.open tmpmergefile, 'w' do |f|
  csvread mergefile do |num, code, kind, desc, contenten, contentme|
    r = rubrics[num.to_i]
    
    puts num
    errs = haveerrors r[:desc], r[:contenten], contentme

    if errs == ''
      r[:contentme] = contentme
    else
      count[desc] ||= 0
      count[desc] += 1
      s = [num, code, kind, desc, contenten, contentme, errs] 
      f.puts s.join("\t")
    end
  end
end

puts 'writing rubrics to '+tmpinfile
File.open tmpinfile, 'w' do |f|
  rubrics.each_with_index do |r,i| 
    if i>0
      s = [i.to_s, r[:code], r[:kind], r[:desc], r[:contenten], r[:contentme]]
      f.puts s.join("\t")
    end
  end
end


puts 'Distribution'
puts count.to_a.sort_by{|e|-e[1]}.to_h
puts "Total: #{count.to_a.map(&:last).inject(:+)}"

puts 'shufling files '
File.delete mergefile
File.rename tmpmergefile, mergefile
File.delete infile
File.rename tmpinfile, infile
