select
	id, underwriting->'previousRepaidLoans', state->'name'
from
	loan
where
	id::text in (select jsonb_array_elements_text(underwriting->'previousRepaidLoans') )
order by
	id
limit 300