
Tools needed:
  - git
  - ruby, best to install with rvm
  - gems installed as in lib/base.rb
  - text editor, sublime recommended with ruby tools

Files:
- data folder
  * all relevant csv/xml files
  * claml-simple is simplified dtd for reference and understanding claml format
  * subfolder ijz contains initial csv's it can be discarded after using join.rb
- lib contains common simple stuff in base.rb and some discarded code in snippetes.rb
- root folder 
  * basic tools ruby files and
  * icd-merge.csv translation file errors extracted by *basicerror* and *merge*
  
Basic tools:

- pull.rb  
  * get data from english claml and extract to icd-en-me initial.csv, initial file for translation
  * inserts # as separator in rubrics texts
  * text kinds go to third column to describe separated texts
  * each rubric gets one line with line number infront for further use

- push.rb 
  * get data form translation file and create icd-me.xml claml
  * errorneus translations are included with !!! or . for fragments in resulting claml
  * might generate error file with references to translation file
  * no error.txt means that there are no errors

- basicerrors.rb
  * get data from translation file, check references, existing translations and # separation
  * errors are going into merge file

- merge.rb
  * get data from merge, merge correct data into using basicerrors algorithm


notes:
- order in language file is important since merging will be based on order when you have consecutive incl/excl or simmilar
- solve preffered/prefferedlong for pdf
- translation of background texts / chapter / incl. / excl. / note: / and this chapter includes...
- what to do with latin?
- icd-o is added by obsolete join tool into translation file and not used for claml generation