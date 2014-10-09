#########################
##### some snipets and tools from the past
##### might be usefull in the future
#########################

def processrubric (dist,ref,r)

  def len (ref)
    count = 0
    ref.children.each do |c|
      if c.name == 'text'
        count += 1 unless empty? c.text
      else
        count += len c
      end
    end
    count
  end

  def content (ref)

    def added (t,a)
      (empty? a) ? t : ( (empty? t) ? a : t+'#'+a )
    end

    t = ''
    ref.children.each do |c|
      t = added(t, (c.name=='text') ? c.text : content(c))
    end
    t
  end

  count = 0
=begin
  fp = ''
  r[:ref] = ref
  r.children.each do |l|
    if l.name == 'Label'
      l.children.each do |c|
        case c.name
          when 'text' 
            t = clean(c.text).gsub(/ /,'')
            if t != ''
              count+=1
              fp+='t'
            end
          when 'Fragment', 'Reference', 'Para', 'List', 'Include'
            count+=1
            fp+=c.name[0]
          when 'Term'
            count+=1
            fp+='S'
          when 'Table'
            count+=1
            fp+='T'
          else
            count+=1
            fp+='X'
        end
        #count += l.children.count 
      end
    end
  end
  #count = count.to_s+':'+fp
  r[:count]=count

=end

  #count = len r

  r[:content] = content r

  #dist[count] ||= 0
  #dist[count] += 1

end

#output = Nokogiri::XML::Builder.new do |xml|
#end

puts 'writing peraout'
File.open 'peraout.xml', 'w' do |f|
=begin
  claml.xpath('//Fragment').each do |t|
    # s = t.to_s.gsub("\n",'').gsub(/\s\s+/,' ').strip
    # p = s.gsub /(^.+)(<\/Reference>)/, '\2'
    s = t.text
    f.puts(t) #if !(s =~ /\[.*\]/) && (s.length>16)
  end
=end
f.write xml

puts 'distribucija'
dista = dist.to_a.sort_by{|e|-e[1]}
dista.each {|d| puts "#{d[0]} - #{d[1]}"}
puts "Total: #{dista.map(&:last).inject(:+)}"



#########################
##### first draft to create basic xml from existing mess
##### outdated - extract from original csvs, montenegrin, latin, mkb, icd-o etc. generate mika.csv for first round of translations
#########################

#encoding: UTF-8

require_relative 'lib/base'

icdxml  = 'data/icd-en.xml'
icdocsv = 'data/icd-o.csv'
mkbcsv  = 'data/mkb.csv'

outfile = 'mika.txt'

q = %w(inclusion exclusion preferred preferredLong definition note text 
       coding-hint introduction footnote modifierlink)

puts 'reading xml'
f = File.open icdxml
xml = Nokogiri::XML f
f.puts

close 'reading icd-o-2-3'
icd={}
CSV.foreach icdocsv do |row|
  code = row[0]
  val = row[1].strip.gsub('"','')
  icd[code] = val
end

puts 'reading excel'
lat={}
mne={}
CSV.foreach mkbcsv, headers: true, col_sep: "\t" do |row|
  row.each do |k,v|
    row[k]='' if !row[k]
  end
  code = row['Šifra'].strip.gsub('*','').gsub('+','').gsub('-','').gsub('"','')
  lats = firstup(UnicodeUtils.downcase(row["Naziv Latinski"].strip.gsub('"','')))
  mnes = firstup(UnicodeUtils.downcase(row["Naziv"].strip.gsub('"','')))
  lat[code] = lats
  mne[code] = mnes
end

puts 'process modifiers'
modifiers = []
xml.xpath('ClaML/Modifier').each do |m|
  m.xpath('Rubric').each do |r|
    r.xpath('Label').each do |l|
      modifiers << {code: m[:code], kind: r[:kind], text: clean(l.text)}
    end
  end
end

puts 'process modifier classes'
modifierclasses = []
xml.xpath('ClaML/ModifierClass').each do |m|
  m.xpath('Rubric').each do |r|
    r.xpath('Label').each do |l|
      modifierclasses << {code: m[:modifier], kind: r[:kind], ref: m[:code], text: clean(l.text)}
    end
  end
end

puts 'process classes'
classes = []
modifiers.each do |m|
  classes << {code: m[:code], kind: m[:kind], text: m[:text]}
    modc = hashfind modifierclasses, :code, m[:code]
  modc.each do |mc|
    classes << {code: m[:code]+'['+mc[:ref]+']', kind: mc[:kind], text: mc[:text]}
  end
end

xml.xpath('ClaML/Class').each do |c|
  c.xpath('Rubric').each do |r|
    r.xpath('Label').each do |l|
      post = ''
      post = "[#{l.xpath('Reference')[0][:code]}]" if r[:kind]=='modifierlink'
      classes << {code: c[:code]+post, kind: r[:kind], text: clean(l.text)}
    end
  end
end

puts 'process montenegrin and latin'
classes.each do |i|
  c = i[:code]
  l = lat[c]
  m = mne[c]
  i[:textm] = m if m
  i[:textl] = l if l
  lat.delete(c) 
  mne.delete(c)
end

lat.each do |key,v|
  
  if key && key!=''

    subcode = key.split('.').last
    code = key.split('.'+subcode).first

    (hashfindstart classes, :code, code).each do |h|
      if h[:kind]=='modifierlink'
        ref = h[:code].split(/(.+)\[(.+)\]/).last
        (hashfindstart classes, :code, ref).each do |c|
          suf = c[:code].split(/(.+)\[(.+)\]/).last.gsub('.','')
          if suf==subcode
            c[:textm]=mne[key]
            c[:textl]=lat[key]
            mne.delete(key)
            lat.delete(key)
          end
        end
      end
    end
  end
end

icd.each do |k,v|
  classes << {code:k, kind:'icd-o', text: v, textm: '', textl: lat[k]||''}
  lat.delete(k) 
  mne.delete(k)
end

puts 'output results'

File.open outfile, 'w' do |fout|

  # classes
  classes.each do |i|
    fout.write "#{i[:code]}\t#{i[:kind]}\t#{i[:text]}\t#{i[:textm]}\t#{i[:textl]}\n"
  end

  # remaining latin
  lat.each do |c,v| 
    fout.write "#{c}\t\t\t"

    m = mne[c]
    fout.write (m ? m : "")+"\t"
    
    fout.write "#{v}\n"
    lat.delete(c)
    mne.delete(c) if m
  end

  # remainin montenegrin
  mne.each do |c,v|
    fout.write "#{c}\t\t\t#{v}\t\n"
  end

end



#########################
##### join, obsolete 
##### merge translation from multiple csv files, icd-o files, and icd-en to create translation file
##### if no errors error file deleted, else create errors.txt and icd-merge.csv
#########################
# join.rb  
#   * uses icd-en.csv for english texts
#   * get data from multiple csv's and generate icd-me.csv and error and merge file
#   * inserts # for separation
#   * includes icd-o which will be ignored for time being
#   * if errors are detected error file is generated and merge file contains error data

#encoding: UTF-8

require_relative 'lib/base'

foldercsv = 'data/ijz/csv/*.csv'
infile    = 'data/icd-en.csv'
inofile   = 'data/icd-o.csv'
outfile   = 'data/icd-en-me.csv'
mergefile = 'icd-merge.csv'
errfile   = 'errors.txt'

def varcsvread (filename, len)
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

# empty error file
@errf = File.open errfile,'w'

last = 0
puts 'reading english csv from '+infile
rubrics = {}
varcsvread infile, 5 do |num, code, kind, desc, content|
  rubrics[code] ||= []
  rubrics[code] << {num: num, kind: kind, desc: desc, content: content, todo: true}
  last = num.to_i
end

puts 'rading icd-o from '+inofile
File.readlines(inofile).each do |line|
  s = line.split ','
  code = clean (s[0])
  content = clean(s[1..-1].join(',').gsub('"',''))
  content = clean(content[0..-2]) if content[-1]==','

  last = last+1
  rubrics[code] ||= []
  rubrics[code] << {num: last.to_s, kind: 'icd-o', desc: '', content: content, todo: true}
end


puts "reading mne csv's from "+foldercsv
Dir[foldercsv].each do |fn|
  fin = fn.split('/').last
  puts 'processing: '+fin
  varcsvread fn, 3 do |num, code, kind, desc, content|
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

puts 'writing extracted rubrics and merge file into '+outfile+' and '+mergefile
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

      if !( empty?(me) || (num == 0) ) # missing translation
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



#########################
##### match, obsolete
##### get data from merge file, add #'s for refference in the end
##### erase corrected from merge file and write to translation file
##### writes to t1 and t2 intermediary just in case
##### uncomment last lines, but be careful, it's destructive on merge files and translation file
#########################
# match.rb 
#   * get data from merge file and incorporate valid ones in icd-me.csv, erase corrected from merge file

#encoding: UTF-8

require_relative 'lib/base'

infile       = 'data/icd-en-me.csv'
tmpinfile    = 't1.csv'
mergefile    = 'icd-merge.csv'
tmpmergefile = 't2.txt'


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

puts 'reading rubrics from '+infile
rubrics = []
csvread infile do |num, code, kind, desc, contenten, contentme|
  rubrics[num.to_i] = {code: code, kind: kind, desc: desc, contenten: contenten, contentme:contentme}
end

puts 'matching and merging to '+tmpmergefile

count = {}
File.open tmpmergefile, 'w' do |f|
  csvread mergefile do |num, code, kind, desc, contenten, contentme|
    count[desc] ||= 0
    count[desc] += 1
    r = rubrics[num.to_i]
    m = merge r[:desc], r[:contenten], contentme
    if m != ''
      count[desc] += -1
      r[:contentme] = m
    else
      s = [num, code, kind, desc, contenten, contentme] 
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

#puts 'shufling files'
#File.delete mergefile
#File.rename tmpmergefile, mergefile
#File.delete infile
#File.rename tmpinfile, infile

