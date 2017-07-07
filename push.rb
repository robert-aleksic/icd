#encoding: UTF-8

require_relative 'lib/base'

inxml  = 'data/icd-en.xml'
incsv  = 'data/icd-en-me.csv'
outxml = 'data/icd-me.xml'
errfile = 'error.txt'


def processrubric (pos, r, me)

  def processchild (pos,c)
  
    case c.name 
      when 'text'
        if !empty?(c.text)
          me = @me[@i]
          en = c.content          
          if c.parent.name == 'Reference'
            if empty?(me) || ((en!=me) && (me.length<16)) # no translation, references differ
              err @infname, "reference mismatch @ #{pos} - #{en} vs. #{me}"
              me = '!!! '+(empty?(me) ? '' : me)
            end
          end
          c.content = !empty?(me) ? me : (c.parent.name=='Fragment' ? '!!!' : "!!! #{en}")
          
          @i += 1          
        end    
      else
        c.children.each {|e|processchild(pos,e)}      
    end
  
  end

  @me = me.split '#'
  @i  = 0
  r.children.each do |c|
    processchild pos, c
  end

end

@infname = incsv

# empty error file
@errf = File.open errfile,'w'

puts 'reading csv from '+incsv
me = []
csvread incsv do |num, code, kind, desc, contenten, contentme|
  me[num.to_i] = contentme
end

puts 'reading claml from '+inxml
xml = nil
File.open inxml do |f| 
  xml = Nokogiri::XML f
end

puts 'substituting language'
claml = xml.root
i = 1
claml.children.each do |c|
  c.children.each do |ch| 
    if ch.name == 'Rubric'
      processrubric(i, ch,me[i])
      i += 1
      puts i if i % 5000 == 0
    end
  end
end

puts 'writing claml '+outxml
File.open outxml, 'w' do |f|
  f.write xml
end


# empty error file
@errf.close
File.delete(errfile) if File.stat(errfile).size == 0
