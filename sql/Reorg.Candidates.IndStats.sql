WITH ash AS(
  SELECT/*+MATERIALIZE CARDINALITY(1000000)*/sql_id,sql_plan_hash_value,sql_plan_line_id,event,
    COUNT(CASE WHEN TO_CHAR(sample_time,'HH24MI') BETWEEN '0900' AND '1830' AND NOT TO_CHAR(sample_time,'DY','nls_date_language=english')IN('SUN','SAT') THEN 1 END)fgtim,
    COUNT(*)cnt
  FROM dba_hist_active_sess_history WHERE sample_time>sysdate-30
  GROUP BY sql_id,sql_plan_hash_value,sql_plan_line_id,event
),plan AS(
  SELECT/*+MATERIALIZE  CARDINALITY(1000000)*/sql_id,plan_hash_value,id,object_owner,object_name,operation,options,search_columns,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LEAD(object_owner)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LAG(object_owner)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END object_owner_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LEAD(object_name)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LAG(object_name)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END object_name_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END operation_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END options_i,
    CASE 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LEAD(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=id AND LEAD(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LEAD(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LEAD(search_columns)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
      WHEN operation='TABLE ACCESS' AND options LIKE 'BY%INDEX ROWID' AND LAG(parent_id)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)=parent_id+1 AND LAG(operation)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id)='INDEX' AND LAG(options)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) IN('UNIQUE SCAN','RANGE SCAN') THEN LAG(search_columns)OVER(PARTITION BY sql_id,plan_hash_value ORDER BY id) 
    END search_columns_i
  FROM dba_hist_sql_plan
),ash_ AS(
  SELECT object_owner,object_name,operation,options,search_columns,event,object_owner_i,object_name_i,operation_i,options_i,search_columns_i,sum(cnt)cnt,ROUND(sum(fgtim)/sum(cnt)*100,2)pct_fg
  FROM ash a LEFT JOIN plan p ON a.sql_id=p.sql_id AND a.sql_plan_hash_value=p.plan_hash_value AND a.sql_plan_line_id=p.id
  GROUP BY object_owner,object_name,operation,options,search_columns,event,object_owner_i,object_name_i,operation_i,options_i,search_columns_i
),ash__ AS(
  SELECT ash_.*,ROUND(cnt/SUM(cnt)OVER()*100,2) pct_total FROM ash_
),ash___ AS(
SELECT DISTINCT NVL((SELECT table_name FROM dba_indexes WHERE owner='REPLACE_OWNER' AND index_name=a.object_name),object_name)base_tab 
FROM ash__ a
WHERE event is not null AND object_owner='REPLACE_OWNER' AND pct_total>=.1 AND operation||' '||options<>'TABLE ACCESS FULL'
)           
SELECT t.table_name,i.index_name,t.num_rows,i.clustering_factor,(t.blocks-t.empty_blocks)tab_blocks,i.num_rows ind_rows,LISTAGG(column_name,',')WITHIN GROUP(ORDER BY column_position)cols 
FROM dba_tables t JOIN dba_indexes i ON t.owner=i.table_owner AND i.table_name=t.table_name JOIN dba_ind_columns c ON i.owner=c.index_owner AND i.index_name=c.index_name JOIN ash___ ON t.table_name=ash___.base_tab AND t.owner='REPLACE_OWNER'
GROUP BY t.table_name,i.index_name,t.num_rows,i.num_rows,(t.blocks-t.empty_blocks),i.clustering_factor
ORDER BY 1,2,3,4