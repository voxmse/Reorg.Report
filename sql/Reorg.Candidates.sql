WITH ash AS(
  SELECT/*+MATERIALIZE CARDINALITY(1000000)*/sql_id,sql_plan_hash_value,sql_plan_line_id,event,
    COUNT(CASE WHEN TO_CHAR(sample_time,'HH24MI') BETWEEN '0900' AND '1830' AND NOT TO_CHAR(sample_time,'DY','nls_date_language=english')IN('SUN','SAT') THEN 1 END)fgtim,
    COUNT(*)cnt
  FROM dba_hist_active_sess_history
  WHERE sample_time>SYSDATE-30 -- AND sql_id IN(SELECT SQL_ID FROM dba_hist_sql_plan WHERE OPERATION='TABLE ACCESS' AND OPTIONS='BY LOCAL INDEX ROWID' AND OBJECT_NAME='ACOPOPERCL' AND SAMPLE_TIME>SYSDATE-30)
  GROUP BY sql_id,sql_plan_hash_value,sql_plan_line_id,event
),plan AS(
  SELECT/*+MATERIALIZE  CARDINALITY(1000000)*/sql_id,plan_hash_value,id,object_owner,object_name,operation,options,search_columns,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LEAD(object_owner)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
      THEN LAG(object_owner)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
           AND LAG(operation,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('ITERATOR','ALL','SINGLE') 
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LAG(parent_id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 
      THEN LAG(object_owner)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id
           AND LAG(operation,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('ITERATOR','ALL','SINGLE') 
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id 
      THEN LEAD(object_owner)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END object_owner_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LEAD(object_name)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' 
           AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LAG(object_name)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
           AND LAG(operation,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('ITERATOR','ALL','SINGLE') 
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LAG(parent_id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 
      THEN LAG(object_name)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)     
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('ITERATOR','ALL','SINGLE') 
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id 
      THEN LEAD(object_name)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END object_name_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
           AND LAG(operation,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='ITERATOR' 
           AND LAG(options,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('ITERATOR','ALL','SINGLE') 
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LAG(parent_id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 
      THEN LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('ITERATOR','ALL','SINGLE') 
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id 
      THEN LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END operation_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
           AND LAG(operation,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('ITERATOR','ALL','SINGLE') 
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LAG(parent_id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 
      THEN LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('ITERATOR','ALL','SINGLE') 
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id 
      THEN LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END options_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SCIP SCAN','FULL SCAN')
      THEN LEAD(search_columns)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID'
           AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX'
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN')
      THEN LAG(search_columns)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
           AND LAG(operation,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('ITERATOR','ALL','SINGLE') 
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LAG(parent_id,2)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 
      THEN LAG(search_columns)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' 
           AND LAG(id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id
           AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) LIKE 'PARTITION %'
           AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('ITERATOR','ALL','SINGLE') 
           AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' 
           AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN','RANGE SCAN DESCENDING','SKIP SCAN','FULL SCAN') 
           AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id 
      THEN LEAD(search_columns)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END search_columns_i
  FROM dba_hist_sql_plan
),ash_ AS(
  SELECT object_owner,object_name,operation,options,search_columns,event,object_owner_i,object_name_i,operation_i,options_i,search_columns_i,sum(cnt)cnt,ROUND(sum(fgtim)/sum(cnt)*100,2)pct_fg
  FROM ash a LEFT JOIN plan p ON a.sql_id=p.sql_id AND a.sql_plan_hash_value=p.plan_hash_value AND a.sql_plan_line_id=p.id
  GROUP BY object_owner,object_name,operation,options,search_columns,event,object_owner_i,object_name_i,operation_i,options_i,search_columns_i
),ash__ AS(
  SELECT ash_.*,cnt/SUM(cnt)OVER()*100 pct_total FROM ash_ 
),ash___ AS(
  SELECT object_owner,object_name,operation,options,search_columns,object_owner_i,object_name_i,operation_i,options_i,search_columns_i,sum(cnt)cnt,sum(pct_fg)pct_fg,round(sum(pct_total),2)pct_total
  FROM ash__ WHERE event LIKE '% read'
  GROUP BY object_owner,object_name,operation,options,search_columns,object_owner_i,object_name_i,operation_i,options_i,search_columns_i
)
SELECT NVL((SELECT table_name FROM dba_indexes WHERE owner='REPLACE_OWNER' AND index_name=a.object_name),object_name)base_tab,
  (SELECT index_name FROM dba_indexes WHERE owner='REPLACE_OWNER' AND index_name IN(a.object_name_i,a.object_name))base_ind,
object_name,operation,options,search_columns cols,object_name_i,operation_i,options_i,search_columns_i cols_i,pct_total,pct_fg FROM ash___ a
WHERE object_owner='REPLACE_OWNER' AND pct_total>=.1 AND operation||' '||options<>'TABLE ACCESS FULL' 
ORDER BY object_name,operation