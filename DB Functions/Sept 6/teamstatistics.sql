DROP FUNCTION public.teamstatistics( integer,  integer,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying,  character varying);
CREATE OR REPLACE FUNCTION public.teamstatistics(_offset integer, _limit integer, _fromdate character varying, _todate character varying, _eligibilityoffice character varying, _county character varying, _sortcolumn character varying, _sortorder character varying, _userid character varying, searchvalue character varying)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

DECLARE result json;
declare total int4;
declare offsetValue int4 = 10;
declare beginyear character varying = '';
declare endyear character varying = '';
declare totalweek float;

begin
    beginyear = concat('01/01/', TO_CHAR(now():: DATE, 'yyyy'));
    endyear = concat('31/12/', TO_CHAR(now():: DATE, 'yyyy'));
--	raise notice 'beginyear: %', beginyear;
--	raise notice 'endyear: %', endyear;
	totalweek:= ceil(EXTRACT(days FROM ((coalesce(to_date(_todate, 'dd-mm-yyyy'),(select max("ReviewedDate") from dbo."MonitoringSequence")) - coalesce(to_date(_fromdate, 'dd-mm-yyyy'),(select min("ReviewedDate") from dbo."MonitoringSequence")))+ interval '1day'))/7.0);

if totalweek = 0 then
   totalweek:=1;
end if;

	raise notice 'totalweek: %', totalweek;

offsetValue = offsetValue * _offset;

if _offset = 0 then


-- select count(t) from (
-- select concat(f.firstname,concat(' ',f.lastname)) as "monitorname",f.id as "id", f.roleid as "roleid" from public.fssauser f
-- inner join dbo."MonitoringSequence" ms on f.id = ms."ReviewedBy"
-- where f.status ='A'
-- and case when _eligibilityoffice = '' then true else string_to_array(f.eligibilityofficerid,',') && _eligibilityoffice::text[] end
-- and case when _county = '' then true else string_to_array(f.countyid,',') && _county::text[] end
-- and case when _userid = '' then true else f.id = any(_userid::int[]) end
-- and case when searchvalue = '' then true else lower(concat(f.firstname,concat(' ',f.lastname))) like lower(searchvalue) end
-- --and f.roleid in ('ccc62245-cb4c-4f90-80bd-884f12dc6600','fc834df1-6e81-459a-a743-59b2502eecc8')
-- group by monitorname, id, roleid
-- )t
-- into total;

select count(t) from (
select concat(f.firstname,' ',f.lastname) as "monitorname",f.id   
from public.fssauser f
inner join public.monitoringsequence_reviewby mr on f.id = mr.review_by
and case when _fromdate = '' and _todate = '' then true else mr.created_at::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') end
INNER JOIN dbo."ReviewHistory" rh2 ON rh2."MonitoringSequenceGenId" = mr."MonitoringSequenceGenId"
inner join dbo."MonitoringSequence" ms on mr."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId" and ms."DeleteDate" is null
where f.status ='A'
AND rh2.status = 'Valid'
and case when _eligibilityoffice = '' then true else string_to_array(f.eligibilityofficerid,',') && _eligibilityoffice::text[] end
and case when _county = '' then true else string_to_array(f.countyid,',') && _county::text[] end
and case when _userid = '' then true else f.id = any(_userid::int[]) end
and case when searchvalue = '' then true else lower(concat(f.firstname,concat(' ',f.lastname))) like lower(searchvalue) end
group by monitorname, f.id
)t
into total;

else

total = 0;

end if;

-- select Json_agg(row_to_json(t1)) from (
-- select
-- t.monitorname
-- ,t.roleid
-- ,(
-- select count(*) from
-- dbo."MonitoringSequence" ms2
-- where ms2."ReviewedBy" = t.id
-- and ms2."DeleteDate" is null
-- and case when _fromdate = '' and _todate = '' then true else ms2."ReviewedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') end
-- ) as "totalreviewed"
-- ,(
-- select count(*) from
-- dbo."MonitoringSequence" ms2
-- where ms2."ReviewedBy" = t.id
-- and ms2."DeleteDate" is null
-- and ms2."ReviewedDate"::date between to_date(beginyear, 'dd-mm-yyyy') and  to_date(endyear, 'dd-mm-yyyy')
-- ) as "reviewedytd"
-- ,(
-- select ABS(count(*) / totalweek) from
-- dbo."MonitoringSequence" ms2
-- where ms2."ReviewedBy" = t.id
-- and ms2."DeleteDate" is null
-- and case when _fromdate = '' and _todate = '' then true else ms2."ReviewedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') end
-- ) as "weeklyaverage"
-- ,(
-- select count(*) from
-- dbo."MonitoringSequence" ms2
-- inner join dbo."Error" e on ms2."MonitoringSequenceGenId" = e."MonitoringSequenceGenId"
-- where ms2."ReviewedBy" = t.id
-- and ms2."DeleteDate" is null
-- and e."DeleteDate" is null
-- and case when _fromdate = '' and _todate = '' then true else ms2."ReviewedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') end
-- ) as "totalerrorfound"
-- ,(
-- select count(*) from
-- dbo."MonitoringSequence" ms2
-- inner join dbo."Error" e on ms2."MonitoringSequenceGenId" = e."MonitoringSequenceGenId"
-- where ms2."ReviewedBy" = t.id
-- and ms2."DeleteDate" is null
-- and e."DeleteDate" is null
-- and ((e."ApprovedInd" is true) OR (e."RemovedByPolicy" IS NOT NULL))
-- and case when _fromdate = '' and _todate = '' then true else ms2."ReviewedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') end
-- ) as "totalerroroverturned"
-- ,(
-- select ROUND(avg(
-- (
-- (DATE_PART('day', rh."EndDate"::timestamp - rh."BeginDate"::timestamp) * 24 +
--       DATE_PART('hour', rh."EndDate"::timestamp - rh."BeginDate"::timestamp) * 60) +
--       DATE_PART('minute', rh."EndDate"::timestamp - rh."BeginDate"::timestamp) * 60
-- )
-- /60)::numeric, 2)  from
-- dbo."MonitoringSequence" ms2
-- inner join dbo."ReviewHistory" rh on ms2."MonitoringSequenceGenId" = rh."MonitoringSequenceGenId"
-- where ms2."ReviewedBy" = t.id
-- and ms2."ReviewedBy" = rh."UserGenId"
-- and case when _fromdate = '' and _todate = '' then true else ms2."ReviewedDate"::date between to_date(_fromdate, 'dd-mm-yyyy') and  to_date(_todate, 'dd-mm-yyyy') end
-- ) as "averageminutesperreview"
-- from
-- (
-- select concat(f.firstname,concat(' ',f.lastname)) as "monitorname",f.id as "id", f.roleid as "roleid" from public.fssauser f
-- inner join dbo."MonitoringSequence" ms on f.id = ms."ReviewedBy"
-- where f.status ='A'
-- and case when _eligibilityoffice = '' then true else string_to_array(f.eligibilityofficerid,',') && _eligibilityoffice::text[] end
-- and case when _county = '' then true else string_to_array(f.countyid,',') && _county::text[] end
-- and case when _userid = '' then true else f.id = any(_userid::int[]) end
-- and case when searchvalue = '' then true else lower(concat(f.firstname,concat(' ',f.lastname))) like lower(searchvalue) end
-- --and f.roleid in ('ccc62245-cb4c-4f90-80bd-884f12dc6600','fc834df1-6e81-459a-a743-59b2502eecc8')
-- group by monitorname, id, roleid
-- order by monitorname asc
-- limit _limit
-- offset offsetValue
-- )t
-- )
-- t1 into result;


SELECT json_agg(row_to_json(t1))
FROM (
    SELECT *
    FROM (
        SELECT *,
            COALESCE(round(ABS(t2.totalminutes / t2.totalreviewed),2),0) AS averageminutesperreview,
             round(t2.totalreviewed / totalweek) AS weeklyaverage
        FROM (
            SELECT
                t.monitorname,
                t.id,
                t."MonitoringSequenceGenId",
                (select  COALESCE(COUNT(distinct mr."MonitoringSequenceGenId"),0)
                from public.monitoringsequence_reviewby mr 
                where (CASE WHEN _fromdate = '' AND _todate = '' THEN TRUE ELSE mr.created_at::date BETWEEN to_date(_fromdate, 'dd-mm-yyyy') AND to_date(_todate, 'dd-mm-yyyy') END)
                and mr.review_by = t.id ) AS totalreviewed,
                (select  COALESCE(COUNT(distinct mr."MonitoringSequenceGenId"),0)
                from public.monitoringsequence_reviewby mr 
                where  mr.created_at::date BETWEEN  DATE_TRUNC('year', CURRENT_DATE)::date AND CURRENT_DATE 
                and mr.review_by = t.id ) AS reviewedytd,
--                COALESCE(COUNT(t."MonitoringSequenceGenId"),0) AS totalreviewed,
--                (select  abs(COALESCE(COUNT(distinct mr."MonitoringSequenceGenId"),0) / totalweek)
--                from public.monitoringsequence_reviewby mr 
--                where (CASE WHEN _fromdate = '' AND _todate = '' THEN TRUE ELSE mr.created_at::date BETWEEN to_date(_fromdate, 'dd-mm-yyyy') AND to_date(_todate, 'dd-mm-yyyy') END)
--                and mr.review_by = t.id )
----                COALESCE(ABS(COUNT(t."MonitoringSequenceGenId") / totalweek),0) 
--                AS weeklyaverage,
--                (select  COALESCE(COUNT(distinct mr."MonitoringSequenceGenId"),0)
--                from public.monitoringsequence_reviewby mr 
--                where mr.created_at::date between DATE_TRUNC('year', CURRENT_DATE)::date
--                   AND CURRENT_DATE and mr.review_by = t.id)AS reviewedytd,
	    		(select  COALESCE(ROUND(sum(EXTRACT(EPOCH FROM (rh."EndDate"::timestamp - rh."BeginDate" ::timestamp))/60)::numeric,2),0)
			    from dbo."ReviewHistory" rh
				where rh."UserGenId" = t."id"
				and rh."EndDate" is not null and rh.status = 'Valid' and ((rh."EndDate"::timestamp - rh."BeginDate" ::timestamp)<=	'00:30:00.000') limit 1) AS totalminutes
            FROM (
                SELECT distinct on(f.id)f.id,CONCAT(f.firstname, ' ', f.lastname) AS monitorname,  ms."MonitoringSequenceGenId"
                FROM public.fssauser f
                INNER JOIN public.monitoringsequence_reviewby mr 
                    ON f.id = mr.review_by
                    AND (CASE WHEN _fromdate = '' AND _todate = '' THEN TRUE ELSE mr.created_at::date BETWEEN to_date(_fromdate, 'dd-mm-yyyy') AND to_date(_todate, 'dd-mm-yyyy') END)
                INNER JOIN dbo."ReviewHistory" rh2
             		ON rh2."MonitoringSequenceGenId" = mr."MonitoringSequenceGenId" and rh2."UserGenId" = f.id
                INNER JOIN dbo."MonitoringSequence" ms 
                    ON mr."MonitoringSequenceGenId" = ms."MonitoringSequenceGenId" 
                    AND ms."DeleteDate" IS NULL
                WHERE f.status = 'A'
                 AND rh2.status = 'Valid'
                 AND case when _eligibilityoffice = '' then true else string_to_array(f.eligibilityofficerid,',') && _eligibilityoffice::text[] end
				AND case when _county = '' then true else string_to_array(f.countyid,',') && _county::text[] end
				and case when _userid = '' then true else f.id = any(_userid::int[]) end
                  AND (CASE WHEN searchvalue = '' THEN TRUE ELSE LOWER(CONCAT(f.firstname, ' ', f.lastname)) LIKE LOWER(searchvalue) END)
                  AND (CASE WHEN _fromdate = '' AND _todate = '' THEN TRUE ELSE mr.created_at::date BETWEEN to_date(_fromdate, 'dd-mm-yyyy') AND to_date(_todate, 'dd-mm-yyyy') END)
                GROUP BY monitorname, f.id, ms."MonitoringSequenceGenId"
            ) t
            GROUP BY t.monitorname, t.id, t."MonitoringSequenceGenId"
        ) t2
    ) t3
    ORDER BY 
        CASE WHEN LOWER(_sortorder) = 'asc' AND LOWER(_sortcolumn) = 'name' THEN t3.monitorname END ASC,
        CASE WHEN LOWER(_sortorder) = 'desc' AND LOWER(_sortcolumn) = 'name' THEN t3.monitorname END DESC,
        CASE WHEN LOWER(_sortorder) = 'asc' AND LOWER(_sortcolumn) = 'totalreviewed' THEN t3.totalreviewed END ASC,
        CASE WHEN LOWER(_sortorder) = 'desc' AND LOWER(_sortcolumn) = 'totalreviewed' THEN t3.totalreviewed END DESC,
        CASE WHEN LOWER(_sortorder) = 'asc' AND LOWER(_sortcolumn) = 'totalminutes' THEN t3.totalminutes END ASC,
        CASE WHEN LOWER(_sortorder) = 'desc' AND LOWER(_sortcolumn) = 'totalminutes' THEN t3.totalminutes END DESC,
        CASE WHEN LOWER(_sortorder) = 'asc' AND LOWER(_sortcolumn) = 'averageminutesperreview' THEN t3.averageminutesperreview END ASC,
        CASE WHEN LOWER(_sortorder) = 'desc' AND LOWER(_sortcolumn) = 'averageminutesperreview' THEN t3.averageminutesperreview END DESC,
        CASE WHEN LOWER(_sortorder) = 'asc' AND LOWER(_sortcolumn) = 'weeklyaverage' THEN t3.weeklyaverage END ASC,
        CASE WHEN LOWER(_sortorder) = 'desc' AND LOWER(_sortcolumn) = 'weeklyaverage' THEN t3.weeklyaverage END DESC,
        CASE WHEN LOWER(_sortorder) = 'asc' AND LOWER(_sortcolumn) = 'reviewedytd' THEN t3.reviewedytd END ASC,
        CASE WHEN LOWER(_sortorder) = 'desc' AND LOWER(_sortcolumn) = 'reviewedytd' THEN t3.reviewedytd END DESC
    LIMIT _limit OFFSET offsetValue
) t1

into result

;

RETURN COALESCE(json_build_array(json_build_object('totalCount',total,'data',coalesce(result,'[]'))),'[]');

 END;
 $function$
;
