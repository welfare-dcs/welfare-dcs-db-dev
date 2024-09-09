DROP FUNCTION public.eoreviewqueue( integer,  integer,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying);
CREATE OR REPLACE FUNCTION public.eoreviewqueue(_offset integer, _limit integer, _casenumber character varying, _intakeagency character varying, _county character varying, _startdate character varying, _enddate character varying, _sortcolumn character varying, _sortorder character varying, _casepriority character varying, _lifecyclecompleted character varying)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

DECLARE result json;
declare total int4;
declare offsetValue int4 = 10;
declare globalId8 int4;
declare globalId12 int4;
declare globalId14 int4;

begin

--    select g."ruleValue"::int into globalId8 from public.globals g where g."globalId" = 8;
    select g."ruleValue"::int into globalId12 from public.globals g where g."globalId" = 12;
    select g."ruleValue"::int into globalId14 from public.globals g where g."globalId" = 14;

    offsetValue = offsetValue * _offset;

if _offset = 0 then

select
count(t)
from
(
select
concat(a2."ApplicantGenId",'-',a2."ApplicationSequence") as "casenumber",a2."LastBatchDate"
, concat(initcap(a."ApplicantFirstName"),' ',initcap(a."ApplicantLastName")) as "applicantname"
, a2."ApplicationSignedDate" as "applicationdate"
, a2."ApplicationSignedDate"::date + (globalId14 || ' days')::interval as "duedate"
,(case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" else null end) as "trigger_date"
,(case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" ::date + (globalId14 || ' days')::interval else null end) as "trigger_due_date"
, (case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date then 'No' else 'Yes' end) as lifecyclecompleted
, rp."PriorityDescription" as "casepriority"
, rc."CountyName" as "county"
, teo.description as "eligibilityoffice"
, ms."MonitoringSequenceGenId" as "monitorsequencegenid"
, ms."ReviewedDate" as "reviewed_date"
, ms."ReviewedBy"
,fsu.firstname,fsu.lastname
from dbo."Applicant" a
join dbo."Application" a2 on a."ApplicantGenId" = a2."ApplicantGenId" and a2."ScanStatusGenId" in (2) and a2."TerminationDate" is null and a2."IsLimitedEligibility" is not true
and case when _casenumber = '' then true else concat(a2."ApplicantGenId",'-',a2."ApplicationSequence") = _casenumber end
and case when _startdate = '' and _enddate = '' then true else a2."ApplicationSignedDate"::date between to_date(_startdate, 'dd-mm-yyyy') and to_date(_enddate, 'dd-mm-yyyy') end
join dbo."MonitoringSequence" ms on ms."ApplicantGenId" = a2."ApplicantGenId" and ms."ApplicationSequence" = a2."ApplicationSequence"
left join dbo."Family" f on a2."ApplicantGenId" = f."ApplicantGenId" and a2."ApplicationSequence" = f."ApplicationSequence" and f."ApplicantInd" is true
left join dbo."ReviewLock" r1 on  r1."ApplicantGenId" = a."ApplicantGenId"
left join dbo."ReviewHistory" rh on rh."ReviewHistoryGenId" = r1."ReviewHistoryGenId"
left join fssauser fsu on rh."UserGenId" = fsu.id
join dbo."ref_Priority" rp on f."PriorityGenId" = rp."PriorityGenId"
join dbo."Address" a3 on a2."ApplicantGenId" = a3."ApplicantGenId" and a2."ApplicationSequence" = a3."ApplicationSequence" and a3."addressInd" is true
left join dbo."ref_County" rc on a3."CountyGenId" = rc."CountyGenId"
left join dbo."IntakeAgency_County" iac on a3."CountyGenId" = iac."CountyGenId"
left join public.teligibilityoffice teo on iac.eligibleofficeid = teo.id
left join public.case_by_scanstatus cbs on  cbs.applicationnumber = concat(a2."ApplicantGenId",'-',a2."ApplicationSequence")
where
case when coalesce(cbs.total,0) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end
--and a2."ApplicationSignedDate"::date > current_date - (globalId12 || ' days')::interval
and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end
and case when _casepriority = '' then true else rp."PriorityGenId" = any(_casepriority ::int[]) end
and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end
and case when _lifecyclecompleted = '{true,false}' then true 
		when _lifecyclecompleted = '{false,true}' then true
		when _lifecyclecompleted = '{true}' then a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date
		when _lifecyclecompleted = '{false}' then a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date end
and (a2.eligibility_no_error is not true)
group by a."ApplicantFirstName",a."ApplicantLastName",a2."ApplicationSignedDate",a2."LastBatchDate",teo.description, ms."ReviewedDate",a2."ApplicantGenId",a2."ApplicationSequence",ms."MonitoringSequenceGenId",fsu.firstname,fsu.lastname,ms."ReviewedBy",rp."PriorityDescription",rc."CountyName"
)t
into total;

else

total = 0;

end if;

select Json_agg(row_to_json(t1)) from (
select
concat(a2."ApplicantGenId",'-',a2."ApplicationSequence") as "casenumber",a2."LastBatchDate"
, concat(initcap(a."ApplicantFirstName"),' ',initcap(a."ApplicantLastName")) as "applicantname"
, a2."ApplicationSignedDate" as "applicationdate"
, a2."ApplicationSignedDate"::date + (globalId14 || ' days')::interval as "duedate"
,(case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" else null end) as "trigger_date"
,(case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" ::date + (globalId14 || ' days')::interval else null end) as "trigger_due_date"
, (case when a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date then 'No' else 'Yes' end) as lifecyclecompleted
, rp."PriorityDescription" as "casepriority"
, rc."CountyName" as "county"
, teo.description as "eligibilityoffice"
, ms."MonitoringSequenceGenId" as "monitorsequencegenid"
, ms."ReviewedDate" as "reviewed_date"
, (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) as "reviewed_by"
,fsu.firstname,fsu.lastname
from dbo."Applicant" a
join dbo."Application" a2 on a."ApplicantGenId" = a2."ApplicantGenId" and a2."ScanStatusGenId" in (2) and a2."TerminationDate" is null and a2."IsLimitedEligibility" is not true
and case when _casenumber = '' then true else concat(a2."ApplicantGenId",'-',a2."ApplicationSequence") = _casenumber end
and case when _startdate = '' and _enddate = '' then true else a2."ApplicationSignedDate"::date between to_date(_startdate, 'dd-mm-yyyy') and to_date(_enddate, 'dd-mm-yyyy') end
join dbo."MonitoringSequence" ms on ms."ApplicantGenId" = a2."ApplicantGenId" and ms."ApplicationSequence" = a2."ApplicationSequence"
left join dbo."Family" f on a2."ApplicantGenId" = f."ApplicantGenId" and a2."ApplicationSequence" = f."ApplicationSequence" and f."ApplicantInd" is true
left join dbo."ReviewLock" r1 on  r1."ApplicantGenId" = a."ApplicantGenId"
left join dbo."ReviewHistory" rh on rh."ReviewHistoryGenId" = r1."ReviewHistoryGenId"
left join fssauser fsu on rh."UserGenId" = fsu.id
join dbo."ref_Priority" rp on f."PriorityGenId" = rp."PriorityGenId"
join dbo."Address" a3 on a2."ApplicantGenId" = a3."ApplicantGenId" and a2."ApplicationSequence" = a3."ApplicationSequence" and a3."addressInd" is true
left join dbo."ref_County" rc on a3."CountyGenId" = rc."CountyGenId"
left join dbo."IntakeAgency_County" iac on a3."CountyGenId" = iac."CountyGenId"
left join public.teligibilityoffice teo on iac.eligibleofficeid = teo.id
left join public.case_by_scanstatus cbs on  cbs.applicationnumber = concat(a2."ApplicantGenId",'-',a2."ApplicationSequence")
where
case when coalesce(cbs.total,0) > 0 and coalesce(a2."ToBeScannedReason",0) in (343) then false else true end
--and a2."ApplicationSignedDate"::date > current_date - (globalId12 || ' days')::interval
and case when _intakeagency = '' then true else teo.id = any(_intakeagency ::int[]) end
and case when _casepriority = '' then true else rp."PriorityGenId" = any(_casepriority ::int[]) end
and case when _county = '' then true else rc."CountyGenId" = any(_county ::int[]) end
and case when _lifecyclecompleted = '{true,false}' then true 
		when _lifecyclecompleted = '{false,true}' then true
		when _lifecyclecompleted = '{true}' then a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date
		when _lifecyclecompleted = '{false}' then a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date end
and (a2.eligibility_no_error is not true)
group by a."ApplicantFirstName",a."ApplicantLastName",a2."ApplicationSignedDate",a2."LastBatchDate",teo.description, ms."ReviewedDate",a2."ApplicantGenId",a2."ApplicationSequence",ms."MonitoringSequenceGenId",fsu.firstname,fsu.lastname,(select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id),rp."PriorityDescription",rc."CountyName"
order by
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('casenumber') then ms."ApplicantGenId" end) asc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('casenumber') then ms."ApplicationSequence" end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('casenumber') then ms."ApplicantGenId" end) desc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('casenumber') then ms."ApplicationSequence" end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('applicantname') then concat(a."ApplicantFirstName",' ', a."ApplicantLastName") end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('applicantname') then concat(a."ApplicantFirstName",' ', a."ApplicantLastName") end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('applicationdate') then a2."ApplicationSignedDate" end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('applicationdate') then a2."ApplicationSignedDate" end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('duedate') then a2."ApplicationSignedDate"::date + (globalId14 || ' days')::interval end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('duedate') then a2."ApplicationSignedDate"::date + (globalId14 || ' days')::interval end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('trigger_date') then  (case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" else null end) end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('trigger_date') then  (case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" else null end) end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('trigger_due_date') then  (case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" ::date + (globalId14 || ' days')::interval else null end) end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('trigger_due_date') then  (case when (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < current_date) and (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval < a2."ScanStatusDate") then a2."ScanStatusDate" ::date + (globalId14 || ' days')::interval else null end) end)desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('eligibilityoffice') then teo.description end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('eligibilityoffice') then teo.description end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('countyname') then rc."CountyName" end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('countyname') then rc."CountyName" end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('casepriority') then rp."PriorityDescription" end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('casepriority') then rp."PriorityDescription" end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('reviewed_date') then ms."ReviewedDate" end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('reviewed_date') then ms."ReviewedDate" end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('lastname') then fsu.lastname end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('lastname') then fsu.lastname end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('reviewed_by') then (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('reviewed_by') then (select concat(f1.lastname ,' ',f1.firstname) from public.fssauser f1 where ms."ReviewedBy" = f1.id) end) desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('lifecyclecompleted') then (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval > current_date) end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('lifecyclecompleted') then (a2."ApplicationSignedDate"::date + (globalId12 || 'days'):: interval >= current_date) end)  desc,
(case when lower(_sortorder) = lower('asc') and lower(_sortcolumn) = lower('LastBatchDate') then a2."LastBatchDate" end) asc,
(case when lower(_sortorder) = lower('desc') and lower(_sortcolumn) = lower('LastBatchDate') then a2."LastBatchDate" end)  desc

limit _limit
offset offsetValue
)t1 into result;


RETURN COALESCE(json_build_array(json_build_object('totalCount',total,'data',coalesce(result,'[]'))),'[]');

 END;
 $function$
;