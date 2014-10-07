#encoding: UTF-8

require_relative 'lib/base'

infile       = 'data/icd-me.csv'
mergefile    = 'icd-merge.csv'


def csvread (filename)
  File.readlines(filename).each do |line|
    if line && !empty?(line)

      num, code, kind, desc, contenten, contentme = line.split("\t")
 
      code = clean(code)
      kind = clean(kind)
      contenten = clean(contenten)
      contentme = clean(contentme)

      yield num, code, kind, desc, contenten, contentme

    end
  end
end


def haveerrors (desc, en, me)

  ena = en.split '#'
  mea = ((me+' ').split '#').map{|el|clean(el)}
  err = []
  
  if mea == [] || mea == ['']
    err << 'nedostaje prevod' 
  else
    err << 'različita dužina' if ena.length != mea.length
  
    rasp = false
    ena.each_with_index do |e,i|
      m = mea[i]
      rasp = true if m==''
      if desc[i] == 'R'
        if m.length < 16 && m != e 
          err << e+' vs. '+m
        end
      end
    end
    err << 'podela pomoću znaka #' if rasp

  end

  return (err == []) ? '' : err.join(';')

end



puts 'extracting mergefile'

File.open mergefile, 'w' do |m|
  csvread infile do |num, code, kind, desc, contenten, contentme|

    puts num if num.to_i/1000*1000 == num.to_i
    r = {num: num, code: code, kind: kind, desc: desc, contenten: contenten, contentme:contentme}

    err = haveerrors desc, contenten, contentme

    if err != ''
      s = [num, code, kind, desc, contenten, contentme, err] 
      m.puts s.join("\t")
    end

  end
end
