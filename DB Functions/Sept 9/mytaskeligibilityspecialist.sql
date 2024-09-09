DROP FUNCTION public.mytaskeligibilityspecialist( integer,  integer,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying);
CREATE OR REPLACE FUNCTION public.mytaskeligibilityspecialist(_offset integer, _limit integer, _intakeagency character varying, _county character varying, _role character varying, _taskfilter character varying, _sortcolumn character varying, _sortorder character varying, _fromdate character varying, _todate character varying)
 RETURNS json
 LANGUAGE plpgsql
AS $function$



DECLARE result json;

declare total int4;

declare offsetValue int4 = 10;

declare globalId14 int4;

declare globalId15 int4;

declare globalId10 int4;

declare globalId8 int4;

declare globalId12 int4;



begin



    select g."ruleValue"::int into globalId14 from public.globals g where g."globalId" = 14;

    select g."ruleValue"::int into globalId15 from public.globals g where g."globalId" = 15;

    select g."ruleValue"::int into globalId10 from public.globals g where g."globalId" = 10;

    select g."ruleValue"::int into globalId8 from public.globals g where g."globalId" = 8;
   
    select g."ruleValue"::int into globalId12 from public.globals g where g."globalId" = 12;





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

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null and coalesce(ece.count,0) > 0 then

case when coalesce(ecea.count,0) > 0 then 'Appeal Denial'

else 'Correction Denial'

end

else 'EO QA Review' end as "task"

, '05/20/2020' as "earliestduedate"

, a."StateCode"

,a.assetovermilliondollar

,rss."ScanStatusDescription" as "scanstatus"

,(case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date then 'No' else 'Yes' end) as lifecyclecompleted

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

inner join dbo."Family" f on ms."ApplicantGenId" = f."ApplicantGenId" and ms."ApplicationSequence" = f."ApplicationSequence" and f."ApplicantInd" is true

left join dbo."ReviewLock" r1 on  r1."ApplicantGenId" = a."ApplicantGenId"

left join dbo."ReviewHistory" rh on rh."ReviewHistoryGenId" = r1."ReviewHistoryGenId"

left join fssauser fsu on rh."UserGenId" = fsu.id

left join dbo."ref_Priority" rp on f."PriorityGenId" = rp."PriorityGenId"

--left join dbo."Error" e on ms."MonitoringSequenceGenId" = e."MonitoringSequenceGenId"

join dbo."Address" a3 on a2."ApplicantGenId" = a3."ApplicantGenId" and a2."ApplicationSequence" = a3."ApplicationSequence" and a3."addressInd" is true

left join dbo."ref_County" rc on a3."CountyGenId" = rc."CountyGenId"

left join dbo."IntakeAgency_County" iac on a3."CountyGenId" = iac."CountyGenId"

left join public.teligibilityoffice teo on iac.eligibleofficeid = teo.id

left join dbo."ref_ScanStatus" rss on a2."ScanStatusGenId" = rss."ScanStatusGenId"

left join public.case_by_scanstatus cbs on  cbs.applicationnumber = concat(a2."ApplicantGenId",'-',a2."ApplicationSequence")

left join public.error_count_es ece on ms."MonitoringSequenceGenId" = ece."MonitoringSequenceGenId"

left join public.error_count_es_appeals ecea on ms."MonitoringSequenceGenId" = ecea."MonitoringSequenceGenId"

left join public.error_count_su_4 ecsu4 on ecsu4."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_queue ecq on ms."MonitoringSequenceGenId" = ecq."MonitoringSequenceGenId"

where
 									
case when coalesce(cbs.total,0) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

and case

when a."StateCode" != 'IN' or a.assetovermilliondollar is true then true

when a2."ScanStatusGenId" = 1 and a2."ApplicationSignedDate" is not null then true

when a2."ScanStatusGenId" = 2 then true

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null and

coalesce(ecsu4.count,0) > 0 then true

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null and coalesce(ece.count,0) > 0 then

case when coalesce(ecea.count,0) > 0 then true

else true

end

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null then true

end

--case

--when a."StateCode" != 'IN' or a.assetovermilliondollar is true then true

--when a2."ScanStatusGenId" in (1,2,4) then true

--end

-- and case when (select count(*) from public.ais_applicationversionscandetail where "CaseNumber"= ms."ApplicantGenId" and "CaseSeqNumber"  = ms."ApplicationSequence" and "ScanStatusCode" in (279,282,3,9)) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

-- and

-- case when f."HasJobSearch" is not null then

--    case when coalesce(fcc.total,0) > 0 then

-- case when coalesce(fchc.total,0) > 0 then

--          case when f."ApplicantRelationshipGenId" in (1) and f."HasJobSearch" is true then

--              false

--             else true

--          end

--     else true

--       end

--    else

--       case when f."ApplicantRelationshipGenId" in (1) and f."HasJobSearch" is true then

--           false

--         else true

--       end

--    end

-- end

-- and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

-- and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

-- and case when _fromdate = '' and _todate = '' then

-- a2."ApplicationSignedDate"::date between current_date - 730 and  current_date

-- else

-- a2."ApplicationSignedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy')

-- end

group by "casenumber", "type", "task", a."StateCode", "assetovermilliondollar", "scanstatus", "earliestduedate",a2."ApplicationSignedDate",a2."ScanStatusGenId",a2."ScanStatusDate",fsu.firstname,fsu.lastname, (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id), ms."ReviewedDate", ecq."MonitoringSequenceGenId"

)t

into total;



else



total = 0;



end if;

select Json_agg(row_to_json(t1)) from (

select

concat(a2."ApplicantGenId",concat('-',a2."ApplicationSequence")) as "casenumber",a2."LastBatchDate"

, ms."ReviewedDate" as "reviewed_date"

, (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) as "reviewed_by"

,fsu.firstname,fsu.lastname

, rp."PriorityDescription" as "type"

, case

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null and coalesce(ece.count,0) > 0 then

case when coalesce(ecea.count,0) > 0 then 'Appeal Denial'

else 'Correction Denial'

end

else 'EO QA Review' end as "task"

--, '05/20/2020' as "earliestduedate"

, a."StateCode"

,a.assetovermilliondollar

,rss."ScanStatusDescription" as "scanstatus"

, case

when a2."ScanStatusGenId" = 1 then a2."ApplicationSignedDate"::date + 9

when a2."ScanStatusGenId" = 2 then a2."ApplicationSignedDate"::date + (globalId14 || ' days')::interval

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null and coalesce(ece.count,0) > 0 then

case when coalesce(ecea.count,0) > 0 then (select a4."AppealDenyDate"::date from dbo."Appeals" a4

join dbo."Error" e3 on a4.errorid = e3."ErrorGenId"

where a4."AppealDenyDate" is not null

and e3."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

limit 1) + (globalId15 || ' days')::interval

else (select e4."UpdateDate"::date from dbo."Error" e4 where e4."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId" and e4."ErrorCategoryGenId" = 2 and e4."ApprovedInd" is false limit 1) + (globalId10 || ' days')::interval

end

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null then a2."ApplicationSignedDate"::date + (globalId8 || ' days')::interval

else '05/20/2020'

end  as "earliestduedate"

,(case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date then 'No' else 'Yes' end) as lifecyclecompleted

,(case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date then 
		case when a2."ScanStatusDate" >= a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval then a2."ScanStatusDate" else null end
		else null end) as "triggerdate"

--,(case when a2."ApplicationSignedDate"::date + (28 || 'days'):: interval > current_date then null else a2."ScanStatusDate" end) as "triggerdate"

from dbo."Applicant" a

join dbo."Application" a2 on a."ApplicantGenId" = a2."ApplicantGenId" and a2."ApplicationSignedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') and a2."TerminationDate" is null and a2."IsLimitedEligibility" is not true

left join dbo."MonitoringSequence" ms on ms."ApplicantGenId" = a2."ApplicantGenId" and ms."ApplicationSequence" = a2."ApplicationSequence"

inner join dbo."Family" f on ms."ApplicantGenId" = f."ApplicantGenId" and ms."ApplicationSequence" = f."ApplicationSequence" and f."ApplicantInd" is true

left join dbo."ReviewLock" r1 on  r1."ApplicantGenId" = a."ApplicantGenId"

left join dbo."ReviewHistory" rh on rh."ReviewHistoryGenId" = r1."ReviewHistoryGenId"

left join fssauser fsu on rh."UserGenId" = fsu.id

left join dbo."ref_Priority" rp on f."PriorityGenId" = rp."PriorityGenId"

--left join dbo."Error" e on ms."MonitoringSequenceGenId" = e."MonitoringSequenceGenId"

join dbo."Address" a3 on a2."ApplicantGenId" = a3."ApplicantGenId" and a2."ApplicationSequence" = a3."ApplicationSequence" and a3."addressInd" is true

left join dbo."ref_County" rc on a3."CountyGenId" = rc."CountyGenId"

left join dbo."IntakeAgency_County" iac on a3."CountyGenId" = iac."CountyGenId"

left join public.teligibilityoffice teo on iac.eligibleofficeid = teo.id

left join dbo."ref_ScanStatus" rss on a2."ScanStatusGenId" = rss."ScanStatusGenId"

left join public.case_by_scanstatus cbs on  cbs.applicationnumber = concat(a2."ApplicantGenId",'-',a2."ApplicationSequence")

left join public.error_count_es ece on ms."MonitoringSequenceGenId" = ece."MonitoringSequenceGenId"

left join public.error_count_es_appeals ecea on ms."MonitoringSequenceGenId" = ecea."MonitoringSequenceGenId"

left join public.error_count_su_4 ecsu4 on ecsu4."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId"

left join public.error_count_queue ecq on ms."MonitoringSequenceGenId" = ecq."MonitoringSequenceGenId"

where

case when coalesce(cbs.total,0) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

and case

when a."StateCode" != 'IN' or a.assetovermilliondollar is true then true

when a2."ScanStatusGenId" = 1 and a2."ApplicationSignedDate" is not null then true

when a2."ScanStatusGenId" = 2 then true

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null and

coalesce(ecsu4.count,0) > 0 then true

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null and coalesce(ece.count,0) > 0 then

case when coalesce(ecea.count,0) > 0 then true

else true

end

when a2."ScanStatusGenId" = 4 and ecq."MonitoringSequenceGenId" is not null then true

end

--case

--when a."StateCode" != 'IN' or a.assetovermilliondollar is true then true

--when a2."ScanStatusGenId" in (1,2,4) then true

--end

-- and case when (select count(*) from public.ais_applicationversionscandetail where "CaseNumber"= ms."ApplicantGenId" and "CaseSeqNumber"  = ms."ApplicationSequence" and "ScanStatusCode" in (279,282,3,9)) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end

-- and

-- case when f."HasJobSearch" is not null then

--    case when coalesce(fcc.total,0) > 0 then

-- case when coalesce(fchc.total,0) > 0 then

--          case when f."ApplicantRelationshipGenId" in (1) and f."HasJobSearch" is true then

--              false

--             else true

--          end

--     else true

--       end

--    else

--       case when f."ApplicantRelationshipGenId" in (1) and f."HasJobSearch" is true then

--           false

--         else true

--       end

--    end

-- end

-- and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end

-- and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end

-- and case when _fromdate = '' and _todate = '' then

-- a2."ApplicationSignedDate"::date between current_date - 730 and  current_date

-- else

-- a2."ApplicationSignedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy')

-- end

group by "casenumber", "type", "task", a."StateCode", "assetovermilliondollar",a2."LastBatchDate", "scanstatus", "earliestduedate",a2."ApplicationSignedDate",a2."ScanStatusGenId",a2."ScanStatusDate",fsu.firstname,fsu.lastname, (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id), ms."ReviewedDate", a2."ApplicantGenId", a2."ApplicationSequence", ecq."MonitoringSequenceGenId"

order by 
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('casenumber') then a2."ApplicantGenId" end) asc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('casenumber') then a2."ApplicationSequence" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('casenumber') then a2."ApplicantGenId" end) desc ,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('casenumber') then a2."ApplicationSequence" end) desc ,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('earliestduedate') then a2."ApplicationSignedDate" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('earliestduedate') then a2."ApplicationSignedDate" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('type') then rp."PriorityDescription" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('type') then rp."PriorityDescription" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('lastname') then fsu.lastname end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('lastname') then fsu.lastname end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('task') then a2."ScanStatusGenId" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('task') then a2."ScanStatusGenId" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('scanstatus') then rss."ScanStatusDescription" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('scanstatus') then rss."ScanStatusDescription" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('reviewed_date') then ms."ReviewedDate" end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('reviewed_date') then ms."ReviewedDate" end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('reviewed_by') then (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('reviewed_by') then (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) end) desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('lifecyclecompleted') then (a2."ApplicationSignedDate"::date + (28 || 'days'):: interval >= current_date) end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('lifecyclecompleted') then (a2."ApplicationSignedDate"::date + (28 || 'days'):: interval >= current_date) end)  desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('triggerdate') then (case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date then 
		case when a2."ScanStatusDate" >= a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval then a2."ScanStatusDate" else null end
		else null end) end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('triggerdate') then (case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date then 
		case when a2."ScanStatusDate" >= a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval then a2."ScanStatusDate" else null end
		else null end) end)  desc,

(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('lastbatchdate') then (a2."LastBatchDate") end) asc,

(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('lastbatchdate') then (a2."LastBatchDate") end)  desc

limit _limit

offset offsetValue

)t1 into result;


RETURN COALESCE(json_build_array(json_build_object('totalCount',total,'data',coalesce(result,'[]'))),'[]');



 END;

 $function$
;
