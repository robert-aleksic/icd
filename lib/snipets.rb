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


#### mika

#encoding: UTF-8

require_relative 'lib/base'

icdxml  = 'data/icd.xml'
icdocsv = 'data/icd.csv'
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


