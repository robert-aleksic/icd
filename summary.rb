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
  if c.name == 'Class' 
    case c[:kind] 
      when 'chapter'
        chapter = {num: c[:code], name: pref(c), sub:[]}
        c.children.each do |ch| 
          if ch.name == 'SubClass'
            chapter[:sub] << ch[:code]
            blocks[ch[:code]] = {}
          end
        end 
        chapters << chapter

      when 'block'
        if blocks[c[:code]]
          blocks[c[:code]] = {name:pref(c) , els:[]}
          c.children.each do |ch| 
            if ch.name == 'SubClass'
              blocks[c[:code]][:els] << ch[:code]
              items[ch[:code]] = {}
            end
          end  
        end

      when 'category'
        items[c[:code]] = {name:pref(c)} if items[c[:code]]
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
        f.puts "  #{i} #{items[i][:name]}"
      end
      f.puts
    end
  end
end
