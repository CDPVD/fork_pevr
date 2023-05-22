{{ config(alias='nb_el_fp') }}

WITH src AS (
	SELECT 
        code_perm
        , annee
        , eco_cen
        , date_deb
        , date_fin
    FROM {{ ref('fact_freq_fp') }}
    WHERE 
        date_fin = ''

)

{# Sum the number of students by population #}
SELECT 
	annee
    , eco_cen
	, COUNT(DISTINCT code_perm) AS nb_eleves
FROM src
GROUP BY 
    annee,
    eco_cen