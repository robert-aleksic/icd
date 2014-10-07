Tools needed:
  - git
  - ruby, best to install with rvm
  - gems installed as in lib/base.rb
  - text editor, sublime recommended with ruby tools

Files:

- all relevant csv/xml files are in data folder
- subfolder ijz in data is there just for initial join it can be discarded afterwards
- lib contains common simple stuff in base.rb and some discarded code in snippetes.rb
- root folder contains basic tools ruby files and
  - join.rb (obsolete) - get data from multiple csv's and generate icd-me.csv and error and merge file, insert # for separation
  - error file from some tools
  - icd-merge file to be edited to correct errors

Basic tools:

- pull.rb (only one run) 

    * get data from claml and extract to language file icd-en.csv
    * inserts # as separator in rubrics texts
    * text kinds go to third column to describe separated texts
    * each rubric gets one line and line number infront for further use

- join.rb (obsolete) 

    - get data from multiple csv's and generate icd-me.csv and error and merge file
    - inserts # for separation
    - includes icd-o which will be ignored for time being
    - if errors are detected error file is generated and merge file contains 

- push.rb - get data form transalation file icd-me.csv and create into claml, might generate error file

- match.rb get data from merge file and incorporate valid ones in icd-me.csv, erase corrected from merge file


notes:
- order in language file is important since merging will be based on order when you have consecutive incl/excl or simmilar
- solve preffered/prefferedlong for pdf
- translation of background texts / chapter / incl. / excl. / note: / and this chapter includes...
