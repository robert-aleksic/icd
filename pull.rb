#encoding: UTF-8

require_relative 'lib/base'

language = 'en'

fileclaml = "data/icd-#{language}.xml"
filecsv   = "data/icd-#{language}.csv"

def processrubric (rubrics, ref, code)

  def letter k
    case k
      when 'List', 'Fragment', 'Reference', 'Para', 'Include', 'Table'
        return k[0]
      when 'Label'
        return 'l'
      when 'Term'
        return 'S'
      else
        return 'x'
    end
  end

  def content (ref)
    def added (t,a)
      (empty? a) ? t : ( (empty? t) ? a : t+'#'+a )
    end
    t = ''
    ref.children.each do |c|
      t = added t, (c.name=='text' ? c.text : content(c))
    end
    t
  end

  def desc (ref,pref)
    d = pref
    me = letter(ref.name)
    ref.children.each do |c|
      if c.name=='text' 
        if !empty?(c.text)
          d += me
        end
      else
        d += desc(c,'')
      end
    end
    d
  end
  
  c = content ref
  d = desc ref,''

  rubrics[code] ||= []
  rubrics[code] << {kind: ref[:kind], desc: d, content:c}
  
end

puts 'reading claml file'
xml = nil
File.open fileclaml do |f| 
  xml = Nokogiri::XML f
end

rubrics = {}

claml = xml.root
claml.children.each do |c|
  case c.name 
    when 'Modifier', 'Class' 
      ref = c[:code]
    when 'ModifierClass' 
      ref = c[:modifier] + "[#{c[:code]}]"
    else ref = nil
  end
  c.children.each do |ch| 
    processrubric(rubrics, ch, ref) if ch.name == 'Rubric'
  end
end

i = 1
puts 'writing extracted rubrics'
File.open filecsv, 'w' do |f|
  rubrics.each do |k,v|
    v.each do |a|
      out = [i.to_s,k.to_s,a[:kind],a[:desc],a[:content]]
      f.write out.join("\t")+"\n"
      i = i+1
    end
  end
end
