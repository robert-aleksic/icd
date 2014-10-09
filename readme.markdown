
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
  * icd-en-me.csv is working translation file
- lib contains common simple stuff in base.rb and some discarded code in snippetes.rb
- root folder 
  * basic tools ruby files and
  * error file from some tools most of the tools erase it when empty
  * merge file (icd-merge.csv) to be edited to correct errors if editing full translation file is cumbersome

Basic tools:

- pull.rb  
  * get data from english claml and extract to language file icd-en.csv might be modified to extract from icd-me.xls
  * inserts # as separator in rubrics texts
  * text kinds go to third column to describe separated texts
  * each rubric gets one line with line number infront for further use

- join.rb  
  * uses icd-en.csv for english texts
  *  get data from multiple csv's and generate icd-me.csv and error and merge file
  * inserts # for separation
  * includes icd-o which will be ignored for time being
  * if errors are detected error file is generated and merge file contains 

- match.rb 
  * get data from merge file and incorporate valid ones in icd-me.csv, erase corrected from merge file

- push.rb 
  * get data form translation file icd-me.csv and create icd-me.xml claml, 
  * might generate error file



notes:
- order in language file is important since merging will be based on order when you have consecutive incl/excl or simmilar
- solve preffered/prefferedlong for pdf
- translation of background texts / chapter / incl. / excl. / note: / and this chapter includes...
