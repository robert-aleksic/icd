#encoding: UTF-8

require_relative 'lib/base'

infile       = 'data/icd-me.csv'
tmpinfile    = 't1.csv'
mergefile    = 'icd-merge.csv'
tmpmergefile = 't2.txt'


def csvread (filename, merge)
  File.readlines(filename).each do |line|
    if line && !empty?(line)

 
      if merge 
        #num, code, kind, desc, len, contenten, contentme = line.split("\t")
        num, code, kind, desc, contenten, contentme = line.split("\t")
      else
        num, code, kind, desc, contenten, contentme = line.split("\t")
      end

      num = num
      code = clean(code)
      kind = clean(kind)
      contenten = clean(contenten)
      contentme = clean(contentme)

      # yield num, code, kind, desc, len, contenten, contentme
      yield num, code, kind, desc, contenten, contentme

    end
  end
end


def merge (desc, en, me)

  ena = en.split '#'
  mea = (me.split '#').map{|el|clean(el)}
  found = false
  
  if ena.length == mea.length
    found = true
  else
    case desc
      when 'lR'
        ref = ena[1]
        pos = me.index(ref)
        if pos
          mea[0] = clean me[0..pos-1]
          mea[1] = clean me[pos..-1]
          found = true
        end
      when 'FFFR'
        ref = ena[2]
        pos = me.index(ref)
        if pos
          mea[0] = clean me[0..pos-1]
          mea[1] = ''
          mea[2] = ''
          mea[3] = clean me[pos..-1]
          found = true
        end
      else
    end
  end

  if found && (ena.length == mea.length)
    mea.join '#'
  else
    ''
  end

end



puts 'reading rubrics'
rubrics = []
#csvread infile, false do |num, code, kind, desc, len, contenten, contentme|
csvread infile, false do |num, code, kind, desc, contenten, contentme|
  rubrics[num.to_i] = {code: code, kind: kind, desc: desc, contenten: contenten, contentme:contentme}
end

puts 'merging...'

count = {}
File.open tmpmergefile, 'w' do |f|
  #csvread mergefile, true do |num, code, kind, desc, len, contenten, contentme|
  csvread mergefile, true do |num, code, kind, desc, contenten, contentme|
    count[desc] ||= 0
    count[desc] += 1
    r = rubrics[num.to_i]
    m = merge r[:desc], r[:contenten], contentme
    if m != ''
      count[desc] += -1
      r[:contentme] = m
    else
      # s = [num, code, kind, desc, len, contenten, contentme] 
      s = [num, code, kind, desc, contenten, contentme] 
      f.puts s.join("\t")
    end
  end
end

puts 'writing rubrics'
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

#puts 'shufling files'
#File.delete mergefile
#File.rename tmpmergefile, mergefile
#File.delete infile
#File.rename tmpinfile, infile
