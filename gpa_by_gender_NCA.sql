--Jose A. asked:
--I was wondering if you can help me. I need the average daily attendance 
--for the year by Gender and Overall GPA by Gender

--NCA Y1 GPA by student with elements:
select studentid
      ,grade_level
      ,lastfirst
      ,gender
      ,round(sum(weighted_gpa_points)/sum(potentialcrhrs),2) as GPA_Y1
      ,listagg(course_y1, ', ') within group (order by course_y1) as elements
from
(select distinct re.studentid
      ,re.grade_level
      ,s.lastfirst
      ,s.gender
      --for some reason gpa points for c+'s are coming in as 2.3000000000000003
      --rounding gpa_points for the sake of consistency.  oh, powerschool...
      ,sg_y1.earnedcrhrs * round(sg_y1.gpa_points,1) as weighted_gpa_points
      ,sg_y1.potentialcrhrs
      ,course_name || ' [' || sg_y1.grade || ']' as course_y1

     --written to the reporting DB (@PS_TEAM) instead of live PS
     --because of the list aggregation function used above that is only supported in Oracle 11g
     --after we upgrade to PS 7.0 in August the underlying db will be on 11g as well
     --and you could write this query directly to the database w/o the reporting
     --intermediary.  if you wanted this to run on the production database 
     --you could just drop the listagg command above and you would get GPAs (but not the elements)
from reenrollments@PS_TEAM re
left outer join storedgrades@PS_TEAM sg_y1 on re.studentid = sg_y1.studentid 
 --only bring back stored grades from 2010-2011 school year
 and sg_y1.termid >= 2000 and sg_y1.termid < 2100 
 and sg_y1.schoolid = 73253 and sg_y1.storecode = 'Y1'
join students@PS_TEAM s on s.id = re.studentid
where re.schoolid = 73253 and re.entrydate >= '01-AUG-10' and re.exitdate < '01-JUL-11'
order by re.grade_level, s.lastfirst)
group by studentid, grade_level, lastfirst, gender
order by grade_level, lastfirst;


--NCA GPA averaged by year & grade:
       --group by cube leaves the aggregate figures as 'null' - for clarity
       --specifying 'all' instead of null
select case when gender is null then 'all'
            else gender end as gender
      --replacing nulls with 'all' results in a data type mismatch
      --thus casting the grade_level (num) into varchar. results in some goofy
      --alphabetization because 9 is interpreted as single digit and 10 as
      --two digits but all in all more clear.
      ,case when grade_level is null then 'all'
            else cast(grade_level as varchar2(2)) end as grade_level
      ,avg_gpa
from
(select gender
      ,grade_level
      ,round(avg(GPA_Y1),2) as avg_gpa
from
(select studentid
      ,grade_level
      ,lastfirst
      ,gender
      ,round(sum(weighted_gpa_points)/sum(potentialcrhrs),2) as GPA_Y1
      ,listagg(course_y1, ', ') within group (order by course_y1) as elements
from
(select distinct re.studentid
      ,re.grade_level
      ,s.lastfirst
      ,s.gender
      --for some reason gpa points for c+'s are coming in as 2.3000000000000003
      --rounding gpa_points for the sake of consistency.  oh, powerschool...
      ,sg_y1.earnedcrhrs * round(sg_y1.gpa_points,1) as weighted_gpa_points
      ,sg_y1.potentialcrhrs
      ,course_name || ' [' || sg_y1.grade || ']' as course_y1
     --written to the reporting DB (@PS_TEAM) instead of live PS
     --because of the list aggregation function used above that is only supported in Oracle 11g
     --after we upgrade to PS 7.0 in August the underlying db will be on 11g as well
     --and you could write this query directly to the database w/o the reporting
     --intermediary.  if you wanted this to run on the production database 
     --you could just drop the listagg command above and you would get GPAs (but not the elements)
from reenrollments@PS_TEAM re
left outer join storedgrades@PS_TEAM sg_y1 on re.studentid = sg_y1.studentid 
 --only bring back stored grades from 2010-2011 school year
 and sg_y1.termid >= 2000 and sg_y1.termid < 2100 
 and sg_y1.schoolid = 73253 and sg_y1.storecode = 'Y1'
join students@PS_TEAM s on s.id = re.studentid
where re.schoolid = 73253 and re.entrydate >= '01-AUG-10' and re.exitdate < '01-JUL-11'
order by re.grade_level, s.lastfirst)
group by studentid, grade_level, lastfirst, gender
order by grade_level, lastfirst)
--perfect place to use 'group by cube' to get the intersections of grade & gender 
--as well as aggregate numbers for comparison the top level
group by cube(gender, grade_level))
order by gender,grade_level;