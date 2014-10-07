Basic tools:

- pull.rb (only one run) 
    get data from claml and extract to language file icd-en.csv
    inserts # as separator in rubrics texts
    text kinds go to third column to describe separated texts
    each rubric gets one line and line number infront for further use

- join.rb (obsolete) 
    get data from multiple csv's and generate icd-me.csv and error and merge file
    inserts # for separation

- push.rb - get data form transalation file icd-me.csv and create into claml, might generate error file

- match.rb get data from merge file and incorporate valid ones in icd-me.csv, erase corrected from merge file


notes:
- order in language file is important since merging will be based on order when you have consecutive incl/excl or simmilar
- solve preffered/prefferedlong for pdf
- translation of background texts / chapter / incl. / excl. / note: / and this chapter includes...