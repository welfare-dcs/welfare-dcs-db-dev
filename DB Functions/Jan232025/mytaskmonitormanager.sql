DROP FUNCTION public.mytaskmonitormanager(int4, int4, varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION public.mytaskmonitormanager(_offset integer, _limit integer, _intakeagency character varying, _county character varying, _role character varying, _taskfilter character varying, _sortcolumn character varying, _sortorder character varying, _fromdate character varying, _todate character varying)
 RETURNS json
 LANGUAGE plpgsql
AS $function$



DECLARE result json;

declare total int4;

declare offsetValue int4 = 10;

declare globalId11 int4;

declare globalId10 int4;

declare globalId8 int4;

declare globalId12 int4;

declare globalId2 int4;



begin



    select g."ruleValue"::int into globalId11 from public.globals g where g."globalId" = 11;

    select g."ruleValue"::int into globalId12 from public.globals g where g."globalId" = 12;

    select g."ruleValue"::int into globalId2 from public.globals g where g."globalId" = 2;

    select g."ruleValue"::int into globalId10 from public.globals g where g."globalId" = 10;

    select g."ruleValue"::int into globalId8 from public.globals g where g."globalId" = 8;



    offsetValue = offsetValue * _offset;



if _offset = 0 then



select

count(t)

from

(

select

concat(a2."ApplicantGenId",concat('-',a2."ApplicationSequence")) as "casenumber"

, ms."ReviewedDate" as "reviewed_date"

, (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) as "reviewed_by"

,fsu.firstname,fsu.lastname

, rp."PriorityDescription" as "type"

, case

when a2."ScanStatusGenId" = 9 then 'Payment Reduction Review - FINAL Report for GAR'

when a2."ScanStatusGenId" = 4 then 'Payment Reduction Preview'

WHEN a2."ScanStatusGenId" = 5 THEN 'Critical Review'

end

as "task"

, '05/20/2020' as "earliestduedate"

, a."StateCode"

,a.assetovermilliondollar

,rss."ScanStatusDescription" as "scanstatus"

, case

when a2."ScanStatusGenId" = 9 then 'Payment Reduction Review - FINAL Report for GAR'

when a2."ScanStatusGenId" = 4 then 'Payment Reduction Preview'

WHEN a2."ScanStatusGenId" = 5 THEN 'Critical Review'

end

as "task"

--, '05/20/2020' as "earliestduedate"

, a."StateCode"

,a.assetovermilliondollar

,rss."ScanStatusDescription" as "scanstatus"

,(case when a2."ApplicationSignedDate"::date + (28 || 'days'):: interval > current_date then 'No' else 'Yes' end) as lifecyclecompleted

--,(case when a2."ApplicationSignedDate"::date + (28 || 'days'):: interval > current_date then null else a2."ScanStatusDate" end) as "triggerdate"

,(case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date then
case when a2."ScanStatusDate" >= a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval then a2."ScanStatusDate" else null end
else null end) as "triggerdate"

--, case

--when ms."ApplicationSequence" = 1 then

-- ms."CreateDate"::date + interval '5 day'

--when ms."ApplicationSequence" != 1 and e."ErrorCategoryGenId" = 2 then

-- e."CreateDate"::date + interval '5 day'

--end as "duedate"

from dbo."Applicant" a

join dbo."Application" a2 on a."ApplicantGenId" = a2."ApplicantGenId" and a2."ApplicationSignedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') and a2."TerminationDate" is null and a2."IsLimitedEligibility" is not true

left join dbo."MonitoringSequence" ms on ms."ApplicantGenId" = a2."ApplicantGenId" and ms."ApplicationSequence" = a2."ApplicationSequence"

inner join dbo."Family" f on a2."ApplicantGenId" = f."ApplicantGenId" and a2."ApplicationSequence" = f."ApplicationSequence" and f."ApplicantInd" is true

left join dbo."ReviewLock" r1 on  r1."ApplicantGenId" = a."ApplicantGenId"

left join dbo."ReviewHistory" rh on rh."ReviewHistoryGenId" = r1."ReviewHistoryGenId"

left join fssauser fsu on rh."UserGenId" = fsu.id

left join dbo."ref_Priority" rp on f."PriorityGenId" = rp."PriorityGenId"

left join dbo."Error" e on ms."MonitoringSequenceGenId" = e."MonitoringSequenceGenId" and e."ErrorCategoryGenId" = 2

join dbo."Address" a3 on a2."ApplicantGenId" = a3."ApplicantGenId" and a2."ApplicationSequence" = a3."ApplicationSequence" and a3."addressInd" is true

left join dbo."ref_County" rc on a3."CountyGenId" = rc."CountyGenId"

left join dbo."IntakeAgency_County" iac on a3."CountyGenId" = iac."CountyGenId"

left join public.teligibilityoffice teo on iac.eligibleofficeid = teo.id

left join dbo."ref_ScanStatus" rss on a2."ScanStatusGenId" = rss."ScanStatusGenId"

left join public.case_by_scanstatus cbs on  cbs.applicationnumber = concat(a2."ApplicantGenId",'-',a2."ApplicationSequence")

left join public.error_count_1 ec1 on ec1."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_2 ec2 on ec2."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_3 ec3 on ec3."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_5 ec5 on ec5."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_6 ec6 on ec6."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_7 ec7 on ec7."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_9_3 ec93 on ec93."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_9_7 ec97 on ec97."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

where

--ms."MonitoringSequenceGenId" not in (select e."MonitoringSequenceGenId" from
--
--dbo."Error" e
--
--left join dbo."Appeals" a3 on a3.errorid = e."ErrorGenId"
-- 
--  where ms."MonitoringSequenceGenId"=e."MonitoringSequenceGenId"
-- 
--  and e."ApprovedInd" is false
-- 
--  and a3.errorid is null
-- 
--  ) and

case when coalesce(cbs.total,0) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

and case

-- 1. A case that has an error marked as cannot be corrected (goes to GAR)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec1.count,0) > 0)) then true

-- 2. A case where an appeal has been denied after 6 days (Days in which a case must be terminated by ES after appeal denial)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec2.count,0) > 0)) then true

-- 3. A case where an error has been corrected but was corrected after 23 days

when (a2."ScanStatusGenId" = 4 and (coalesce(ec3.count,0) > 0)) then true

-- 4. A case has been singed by provider but no documents were scanned within 13 (Days in which no documents were not scanned  to notify ES to terminate the case)

when a2."ScanStatusGenId" = 4 and a2."ApplicationSignedDate"::date < current_date - (globalId2 || ' days')::interval then true

-- 5. A case in which errors have not been corrected within 13 days (Days in which eligibility errors must be fixed )

when (a2."ScanStatusGenId" = 4 and (coalesce(ec5.count,0) > 0)) then true

-- 6. A case in which correction was denied, no appeal was created, no termination(Days in which a correction denial may be appealed)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec6.count,0) > 0)) then true

-- 7. A case in which errors are outstanding (no fixed date) after 23 days (Days in which a case with critical errors appear on the Preview Payment Reduction report)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec7.count,0) > 0)) then true

when a2."ScanStatusGenId"  = 5 then true

-- 1. A case that has an error marked as cannot be corrected (goes to GAR)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec1.count,0) > 0)) then true

-- 2. A case where an appeal has been denied after 6 days (Days in which a case must be terminated by ES after appeal denial)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec2.count,0) > 0)) then true

-- 3. A case where an error has been corrected but was corrected after 23 days

when (a2."ScanStatusGenId" = 9 and (coalesce(ec93.count,0) > 0)) then true

-- 4. A case has been singed by provider but no documents were scanned within 13 (Days in which no documents were not scanned  to notify ES to terminate the case)

when a2."ScanStatusGenId" = 9 and a2."ApplicationSignedDate"::date < current_date - (globalId2 || ' days')::interval then true

-- 5. A case in which errors have not been corrected within 13 days (Days in which eligibility errors must be fixed )

when (a2."ScanStatusGenId" = 9 and (coalesce(ec5.count,0) > 0)) then true

-- 6. A case in which correction was denied, no appeal was created, no termination(Days in which a correction denial may be appealed)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec6.count,0) > 0)) then true

-- 7. A case in which errors are outstanding (no fixed date) after 23 days (Days in which a case with critical errors appear on the Preview Payment Reduction report)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec97.count,0) > 0)) then true

end

--case

--when a2."ScanStatusGenId" in (4,9,5) then true

--end

--case

--when a2."ScanStatusGenId" in (4,9,5) then true

--end

-- and case when (select count(*) from public.ais_applicationversionscandetail where "CaseNumber"= ms."ApplicantGenId" and "CaseSeqNumber"  = ms."ApplicationSequence" and "ScanStatusCode" in (279,282,3,9)) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

-- and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

-- and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

-- and case when _fromdate = '' and _todate = '' then

-- a2."ApplicationSignedDate"::date between current_date - 730 and  current_date

-- else

-- a2."ApplicationSignedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy')

-- end

group by "casenumber", "type", "task", a."StateCode", "assetovermilliondollar", "scanstatus", "earliestduedate",a2."ApplicationSignedDate",a2."ScanStatusDate",fsu.firstname,fsu.lastname, (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id), ms."ReviewedDate"

)t

into total;



else



total = 0;


end if;

select Json_agg(row_to_json(t1)) from (

select t.* from
(
select a2."ApplicantGenId", a2."ApplicationSequence" ,ms."ReviewedDate", rss."ScanStatusDescription", a2."ScanStatusGenId", rp."PriorityDescription"
,a2."ApplicationSignedDate",a2."ScanStatusDate",ms."ReviewedBy",

concat(a2."ApplicantGenId",concat('-',a2."ApplicationSequence")) as "casenumber"

, ms."ReviewedDate" as "reviewed_date"

, (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) as "reviewed_by"

,fsu.firstname,fsu.lastname

, rp."PriorityDescription" as "type"

, case

when a2."ScanStatusGenId" = 9 then 'Payment Reduction Review - FINAL Report for GAR'

when a2."ScanStatusGenId" = 4 then 'Payment Reduction Preview'

WHEN a2."ScanStatusGenId" = 5 THEN 'Critical Review'

end

as "task"

--, '05/20/2020' as "earliestduedate"

, a."StateCode"

,a.assetovermilliondollar

,rss."ScanStatusDescription" as "scanstatus"

, case

when a2."ScanStatusGenId" = 5 then a2."ApplicationSignedDate"::date + (globalId8 || ' days')::interval

when a2."ScanStatusGenId" = 4 then

e."CreateDate"::date

+ (globalId12 || ' days')::interval

when a2."ScanStatusGenId" = 9 then

e."CreateDate"::date

+ (globalId12 || ' days')::interval

else '05/20/2020'

end  as "earliestduedate"

--,(case when a2."ApplicationSignedDate"::date + (28 || 'days'):: interval > current_date then 'No' else 'Yes' end) as lifecyclecompleted

, case

when a2."ScanStatusGenId" = 9 then 'Payment Reduction Review - FINAL Report for GAR'

when a2."ScanStatusGenId" = 4 then 'Payment Reduction Preview'

WHEN a2."ScanStatusGenId" = 5 THEN 'Critical Review'

end

as "task"

--, '05/20/2020' as "earliestduedate"

, a."StateCode"

,a.assetovermilliondollar

,rss."ScanStatusDescription" as "scanstatus"

,(case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval > current_date then 'No' else 'Yes' end) as lifecyclecompleted

,(case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date then
case when a2."ScanStatusDate" >= a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval then a2."ScanStatusDate" else null end
else null end) as "triggerdate"

--,(case when a2."ApplicationSignedDate"::date + (28 || 'days'):: interval > current_date then null else a2."ScanStatusDate" end) as "triggerdate"

from dbo."Applicant" a

join dbo."Application" a2 on a."ApplicantGenId" = a2."ApplicantGenId" and a2."ApplicationSignedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') and a2."TerminationDate" is null and a2."IsLimitedEligibility" is not true

left join dbo."MonitoringSequence" ms on ms."ApplicantGenId" = a2."ApplicantGenId" and ms."ApplicationSequence" = a2."ApplicationSequence"

inner join dbo."Family" f on a2."ApplicantGenId" = f."ApplicantGenId" and a2."ApplicationSequence" = f."ApplicationSequence" and f."ApplicantInd" is true

left join dbo."ReviewLock" r1 on  r1."ApplicantGenId" = a."ApplicantGenId"

left join dbo."ReviewHistory" rh on rh."ReviewHistoryGenId" = r1."ReviewHistoryGenId"

left join fssauser fsu on rh."UserGenId" = fsu.id

left join dbo."ref_Priority" rp on f."PriorityGenId" = rp."PriorityGenId"

left join dbo."Error" e on ms."MonitoringSequenceGenId" = e."MonitoringSequenceGenId" and e."ErrorCategoryGenId" = 2

join dbo."Address" a3 on a2."ApplicantGenId" = a3."ApplicantGenId" and a2."ApplicationSequence" = a3."ApplicationSequence" and a3."addressInd" is true

left join dbo."ref_County" rc on a3."CountyGenId" = rc."CountyGenId"

left join dbo."IntakeAgency_County" iac on a3."CountyGenId" = iac."CountyGenId"

left join public.teligibilityoffice teo on iac.eligibleofficeid = teo.id

left join dbo."ref_ScanStatus" rss on a2."ScanStatusGenId" = rss."ScanStatusGenId"

left join public.case_by_scanstatus cbs on  cbs.applicationnumber = concat(a2."ApplicantGenId",'-',a2."ApplicationSequence")

left join public.error_count_1 ec1 on ec1."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_2 ec2 on ec2."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_3 ec3 on ec3."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_5 ec5 on ec5."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_6 ec6 on ec6."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_7 ec7 on ec7."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_9_3 ec93 on ec93."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_9_7 ec97 on ec97."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

where

--ms."MonitoringSequenceGenId" not in (select e."MonitoringSequenceGenId" from
--
--dbo."Error" e
--
--left join dbo."Appeals" a3 on a3.errorid = e."ErrorGenId"
-- 
--  where ms."MonitoringSequenceGenId"=e."MonitoringSequenceGenId"
-- 
--  and e."ApprovedInd" is false
-- 
--  and a3.errorid is null
-- 
--  ) and

case when coalesce(cbs.total,0) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

and case

-- 1. A case that has an error marked as cannot be corrected (goes to GAR)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec1.count,0) > 0)) then true

-- 2. A case where an appeal has been denied after 6 days (Days in which a case must be terminated by ES after appeal denial)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec2.count,0) > 0)) then true

-- 3. A case where an error has been corrected but was corrected after 23 days

when (a2."ScanStatusGenId" = 4 and (coalesce(ec3.count,0) > 0)) then true

-- 4. A case has been singed by provider but no documents were scanned within 13 (Days in which no documents were not scanned  to notify ES to terminate the case)

when a2."ScanStatusGenId" = 4 and a2."ApplicationSignedDate"::date < current_date - (globalId2 || ' days')::interval then true

-- 5. A case in which errors have not been corrected within 13 days (Days in which eligibility errors must be fixed )

when (a2."ScanStatusGenId" = 4 and (coalesce(ec5.count,0) > 0)) then true

-- 6. A case in which correction was denied, no appeal was created, no termination(Days in which a correction denial may be appealed)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec6.count,0) > 0)) then true

-- 7. A case in which errors are outstanding (no fixed date) after 23 days (Days in which a case with critical errors appear on the Preview Payment Reduction report)

when (a2."ScanStatusGenId" = 4 and (coalesce(ec7.count,0) > 0)) then true

when a2."ScanStatusGenId"  = 5 then true

-- 1. A case that has an error marked as cannot be corrected (goes to GAR)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec1.count,0) > 0)) then true

-- 2. A case where an appeal has been denied after 6 days (Days in which a case must be terminated by ES after appeal denial)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec2.count,0) > 0)) then true

-- 3. A case where an error has been corrected but was corrected after 23 days

when (a2."ScanStatusGenId" = 9 and (coalesce(ec93.count,0) > 0)) then true

-- 4. A case has been singed by provider but no documents were scanned within 13 (Days in which no documents were not scanned  to notify ES to terminate the case)

when a2."ScanStatusGenId" = 9 and a2."ApplicationSignedDate"::date < current_date - (globalId2 || ' days')::interval then true

-- 5. A case in which errors have not been corrected within 13 days (Days in which eligibility errors must be fixed )

when (a2."ScanStatusGenId" = 9 and (coalesce(ec5.count,0) > 0)) then true

-- 6. A case in which correction was denied, no appeal was created, no termination(Days in which a correction denial may be appealed)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec6.count,0) > 0)) then true

-- 7. A case in which errors are outstanding (no fixed date) after 23 days (Days in which a case with critical errors appear on the Preview Payment Reduction report)

when (a2."ScanStatusGenId" = 9 and (coalesce(ec97.count,0) > 0)) then true

end

--case

--when a2."ScanStatusGenId" in (4,9,5) then true

--end

--case

--when a2."ScanStatusGenId" in (4,9,5) then true

--end

-- and case when (select count(*) from public.ais_applicationversionscandetail where "CaseNumber"= ms."ApplicantGenId" and "CaseSeqNumber"  = ms."ApplicationSequence" and "ScanStatusCode" in (279,282,3,9)) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

-- and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

-- and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

-- and case when _fromdate = '' and _todate = '' then

-- a2."ApplicationSignedDate"::date between current_date - 730 and  current_date

-- else

-- a2."ApplicationSignedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy')

-- end

group by "casenumber", "type", "task", a."StateCode", "assetovermilliondollar", "scanstatus", "earliestduedate",a2."ApplicationSignedDate",a2."ScanStatusDate",fsu.firstname,fsu."lastname", (select concat(f1."lastname" ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id), ms."ReviewedDate", a2."ApplicantGenId", a2."ApplicationSequence", ms."ReviewedBy"
)t
order by 
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('casenumber') then t."ApplicantGenId" end) asc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('casenumber') then t."ApplicationSequence" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('casenumber') then t."ApplicantGenId" end) desc ,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('casenumber') then t."ApplicationSequence" end) desc ,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('earliestduedate') then t."ApplicationSignedDate" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('earliestduedate') then t."ApplicationSignedDate" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('type') then t."PriorityDescription" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('type') then t."PriorityDescription" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('lastname') then t.lastname end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('lastname') then t.lastname end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('task') then t."ScanStatusGenId" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('task') then t."ScanStatusGenId" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('scanstatus') then t."ScanStatusDescription" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('scanstatus') then t."ScanStatusDescription" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('reviewed_date') then t."ReviewedDate" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('reviewed_date') then t."ReviewedDate" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('reviewed_by') then (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where t."ReviewedBy" = f1.id) end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('reviewed_by') then (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where t."ReviewedBy" = f1.id) end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('lifecyclecompleted') then (t."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date) end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('lifecyclecompleted') then (t."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date) end)  desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('triggerdate') then (case when t."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date then 
		case when t."ScanStatusDate" >= t."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval then t."ScanStatusDate" else null end
		else null end) end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('triggerdate') then (case when t."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date then 
		case when t."ScanStatusDate" >= t."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval then t."ScanStatusDate" else null end
		else null end) end)  desc

limit _limit

offset offsetValue
)t1 into result;



RETURN COALESCE(json_build_array(json_build_object('totalCount',total,'data',coalesce(result,'[]'))),'[]');



 END;

 $function$
;
