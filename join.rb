#encoding: UTF-8

require_relative 'lib/base'

foldercsv = 'data/ijz/csv/*.csv'
infile    = 'data/icd-en.csv'
inofile   = 'data/icd-o.csv'
outfile   = 'data/icd-me.csv'
mergefile = 'icd-merge.csv'
errfile   = 'errors.txt'

def csvread (filename, len)
  File.readlines(filename).each do |line|
    if line && !empty?(line)

 
      case len 
        when 3 
          code, kind, content = line.split("\t")
        when 5
          num, code, kind, desc, content = line.split("\t")
      end

      code = clean(code)
      kind = clean(kind)
      content = clean(content)

      yield num, code, kind, desc, content

    end
  end
end

def err file, s
  @errf.puts "file: #{file} - "+s
end



# empty error file
@errf = File.open errfile,'w'

last = 0
puts 'reading english csv'
rubrics = {}
csvread infile, 5 do |num, code, kind, desc, content|
  rubrics[code] ||= []
  rubrics[code] << {num: num, kind: kind, desc: desc, content: content, todo: true}
  last = num.to_i
end

puts 'rading icd-o'
File.readlines(inofile).each do |line|
  s = line.split ','
  code = clean (s[0])
  content = clean(s[1..-1].join(',').gsub('"',''))
  content = clean(content[0..-2]) if content[-1]==','

  last = last+1
  rubrics[code] ||= []
  rubrics[code] << {num: last.to_s, kind: 'icd-o', desc: '', content: content, todo: true}
end


puts 'reading mne csv'
Dir[foldercsv].each do |fn|
  fin = fn.split('/').last
  puts 'processing: '+fin
  csvread fn, 3 do |num, code, kind, desc, content|
    code = code.gsub(/\[.*\]/,'') if kind=='modifierlink'
    if !rubrics[code]
      err fin, "nonexisting code [#{code},#{kind},#{content}]"
    else
      a = rubrics[code]
      done = false
      i = 0
      while !done and i<a.length do
        if !(a[i][:todo] && (a[i][:kind]==kind))
          i += 1
        else
          done = true
          a[i][:todo] = false
          a[i][:contentme] = content
        end
      end
      if not done
        err fin,"nonexisting match [#{code},#{kind},#{content}]"
      end
    end
  end
end

puts 'writing extracted rubrics and merge file'
File.open mergefile, 'w' do |m|
File.open outfile, 'w' do |f|
  rubrics.each do |k,v|
    v.each do |a|
      eng = a[:content]
      if !a[:contentme] || a[:todo]
        #err 'output',"missing translation [#{k},#{a[:kind]},#{a[:content]}]"
        me = ''
      else
        me = a[:contentme]
      end
      
      num = eng.split('#').length-1
      s = [a[:num],k.to_s,a[:kind],a[:desc],eng,me]
      f.puts s.join("\t")

      if !( empty?(me) || (num == 0) )
        # s = [a[:num],k.to_s,a[:kind],a[:desc],num+1,eng,me]
        s = [a[:num],k.to_s,a[:kind],a[:desc],eng,me]
        m.puts s.join("\t")
      end
    end
  end
end
end

# empty error file
@errf.close
File.delete(errfile) if File.stat(errfile).size == 0
