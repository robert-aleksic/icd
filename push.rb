#encoding: UTF-8

require_relative 'lib/base'

inxml  = 'data/icd-en.xml'
incsv  = 'data/icd-me.csv'
outxml = 'data/icd-me.xml'
errfile = 'error.txt'



def csvread (filename)
  File.readlines(filename).each do |line|
    if line && !empty?(line)
      num, code, kind, desc, contenten, contentme = line.split("\t")

      num = num
      code = clean(code)
      kind = clean(kind)
      contenten = clean(contenten)
      contentme = clean(contentme)

      yield num, code, kind, desc, contenten, contentme
    end
  end
end

def processrubric (pos, r, me)

  def processchild (pos,c)
  
    case c.name 
      when 'text'
        if !empty?(c.text)
          me = @me[@i]
          en = c.content          
          if c.parent.name == 'Reference'
            #me = en if empty? me
            #me = me[0..me.length-1] if me.length>1 && me.last==')'
            if empty?(me) || ((en!=me) && (me.length<16))
              err('csv', "#{pos}: #{en} vs. #{me}")
              me = '!!! '+(empty?(me) ? '' : me)
            end
          end
          c.content = empty?(me) && (c.parent.name != 'Fragment') ? "!!! #{en}" : me
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




# empty error file
@errf = File.open errfile,'w'


puts 'reading csv'
me = []
csvread incsv do |num, code, kind, desc, contenten, contentme|
  me[num.to_i] = contentme
end

puts 'reading claml'
xml = nil
File.open inxml do |f| 
  xml = Nokogiri::XML f
end

puts 'substituting'
claml = xml.root
i = 1
claml.children.each do |c|
  c.children.each do |ch| 
    if ch.name == 'Rubric'
      processrubric(i, ch,me[i])
      i += 1
    end
  end
end

puts 'writing claml'
File.open outxml, 'w' do |f|
  f.write xml
end


# empty error file
@errf.close
File.delete(errfile) if File.stat(errfile).size == 0
