#encoding: UTF-8

require_relative 'lib/base'

infile       = 'data/icd-en-me.csv'
mergefile    = 'icd-merge.csv'

puts 'extracting mergefile from '+infile+' into '+mergefile

File.open mergefile, 'w' do |m|
  csvread infile do |num, code, kind, desc, contenten, contentme|

    # puts num if num.to_i/1000*1000 == num.to_i # progres indicator
    err = haveerrors desc, contenten, contentme

    if err != ''
      s = [num, code, kind, desc, contenten, contentme, err]
      m.puts s.join("\t")
    end

  end
end
