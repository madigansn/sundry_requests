select base_studentid
      ,base_lastfirst
      ,base_schoolid
      ,base_grade_level
--full year      
      ,absences_undoc + absences_doc as absences_total
      ,absences_undoc
      ,absences_doc
      ,tardies_reg + tardies_T10 as tardies_total
      ,tardies_reg
      ,tardies_T10
      ,iss
      ,oss
      ,sum(mem_reg.studentmembership) as mem
from
(select base_studentid
      ,base_lastfirst
      ,base_schoolid
      ,base_grade_level
--full year
      ,sum(case
           when att_code = 'A'
           then 1
           else 0
           end) as absences_undoc
      ,sum(case
           when att_code = 'AD'
           then 1
           when att_code = 'D'
           then 1
           else 0
           end) as absences_doc
      ,sum(case
           when att_code = 'T'
           then 1
           else 0
           end) as tardies_reg
       ,sum(case
           when att_code = 'T10'
           then 1
           else 0
           end) as tardies_T10
       ,sum(case
           when att_code = 'S'
           then 1
           else 0
           end) as ISS
       ,sum(case
           when att_code = 'OS'
           then 1
           else 0
           end) as OSS
from
(select distinct re.studentid as base_studentid
                ,s.lastfirst as base_lastfirst
                ,re.schoolid as base_schoolid
                ,re.grade_level as base_grade_level
                ,psad.att_date
                ,psad.att_code
from reenrollments@PS_TEAM re
join students@PS_TEAM s on re.studentid = s.id and s.entrydate >= '01-AUG-10'
left outer join PS_ATTENDANCE_DAILY@PS_TEAM psad     on s.id = psad.studentid 
                                            and psad.att_date >= '01-AUG-10'
                                            and psad.att_date <  '01-JUL-11'
                                            and psad.att_code is not null
where re.entrydate >= '01-AUG-10' and re.exitdate < '01-JUL-11' and re.schoolid = 73253
order by re.schoolid, re.grade_level, s.lastfirst, psad.att_date)
group by base_studentid, base_lastfirst, base_schoolid, base_grade_level
order by base_schoolid, base_grade_level, base_lastfirst)
left outer join pssis_membership_reg@PS_TEAM mem_reg on base_studentid = mem_reg.studentid 
                                                    and mem_reg.calendardate >  '01-AUG-10' 
                                                    and mem_reg.calendardate <= '01-JUL-11'
                                                    and mem_reg.calendarmembership = 1
group by base_studentid
        ,base_lastfirst
        ,base_schoolid
        ,base_grade_level
        ,absences_undoc
        ,absences_doc
        ,tardies_reg
        ,tardies_T10
        ,iss
        ,oss;