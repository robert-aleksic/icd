#encoding: UTF-8

require_relative 'lib/base'

inxml  = 'data/icd-me.xml'
outtxt = 'data/summary.txt'

def pref c 
  name = ''
  c.children.each do |ch|
    name = clean(ch.content) if ch.name == 'Rubric' && ch[:kind] == 'preferred'
  end
  name
end



puts 'reading claml from '+inxml
xml = nil
File.open inxml do |f| 
  xml = Nokogiri::XML f
end
claml = xml.root

puts 'extracting data... '
chapters = []
blocks = {}
items = {}
claml.children.each do |c|
  
  code = c[:code]
  if c.name == 'Class' 
    case c[:kind] 
      when 'chapter'
        chapter = {num: code, name: pref(c), sub:[]}
        c.children.each do |ch| 
          if ch.name == 'SubClass'
            chapter[:sub] << ch[:code]
            blocks[ch[:code]] = {}
          end
        end 
        
        chapters << chapter

      when 'block'
        if blocks[code]
          blocks[code] = {name:pref(c) , els:[]}
          arr = []
          c.children.each do |ch| 
            if ch.name == 'SubClass'
              if !ch[:code].include?('-') 
                blocks[code][:els] << ch[:code]
                items[ch[:code]] = {}
              else
                arr << ch[:code]
                blocks[ch[:code]] = {}
              end
            end
          end
          if arr!=[]
            case code[0]
              when 'C'
                chp = 1
              when 'M' 
                chp = 12
              when 'T' 
                chp = 18
              when 'V', 'W', 'Y'
                chp = 19
            end
            pos = chapters[chp][:sub].index(code)
            #puts "chp: #{chp}, arr: #{arr}, code: #{code}, pos: #{pos}, chapter: #{chapters[chp][:sub]}" if chp==1
            chapters[chp][:sub].insert(pos+1,arr).flatten!
          end  
        end

      when 'category'
        if items[code]
          dagger = ( c[:usage] == 'dagger') ? '†' : '' 
          items[code] = {name:pref(c), dag: dagger} 
        end
      else
    end
  end
end

puts 'writing summary to '+outtxt
File.open outtxt, 'w' do |f|
  chapters.each do |c|
    
    f.puts "Poglavlje #{c[:num]}"
    f.puts c[:name] 
    f.puts "(#{c[:sub].first[0..2]}-#{c[:sub].last[-3..-1]})"
    f.puts

    c[:sub].each do |s|
      f.puts "  #{blocks[s][:name]} (#{s})"
      f.puts
      blocks[s][:els].each do |i|
        if items[i] 
          #puts i,items[i]
          f.puts "  #{i+items[i][:dag]}\t#{items[i][:name]}"
        end
      end
      f.puts
    end
  end
end
