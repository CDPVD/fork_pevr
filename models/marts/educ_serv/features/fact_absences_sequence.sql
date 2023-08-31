{#
    Compute the sequence of days with at least one periode of absence.
#}
-- Extract all the days a student is expected to be there 
with
    expected_cal as (
        select
            case
                when month(date_evenement) <= 7
                then year(date_evenement) - 1
                else year(date_evenement)
            end as school_year,
            id_eco,
            date_evenement
        from {{ ref("i_gpm_t_cal") }} as cal
        where jour_cycle is not null and grille in ('1', 'A')

    -- Add a sequence id : day_id to later identify the break between two sequences of
    -- absences
    ),
    expected_cal_with_id as (
        select
            school_year,
            id_eco,
            date_evenement,
            row_number() over (
                partition by id_eco, school_year order by date_evenement
            ) as day_id
        from expected_cal

    -- Left join the observed absences on the calendar
    ),
    observed as (
        select exp.school_year, exp.id_eco, exp.date_evenement, exp.day_id, abs.fiche
        from expected_cal_with_id as exp
        inner join
            {{ ref("stg_absences_per_period") }} as abs
            on exp.id_eco = abs.id_eco
            and exp.date_evenement = abs.date_abs

    -- Get the between-sequences-of-absences breaks by checking if the previous day
    -- was a day of absence too
    ),
    breaks as (
        select
            school_year,
            id_eco,
            date_evenement,
            day_id,
            case
                when
                    day_id - lag(day_id) over (
                        partition by school_year, id_eco, fiche order by day_id
                    )
                    > 1
                then 1
                else 0
            end as sequence_break,
            fiche
        from observed

    -- SUM over the break id to get a sequence_id
    ),
    sequences as (
        select
            school_year,
            id_eco,
            date_evenement,
            day_id,
            fiche,
            sum(sequence_break) over (
                partition by school_year, id_eco, fiche
                order by day_id
                rows between unbounded preceding and current row
            ) as absence_sequence_id
        from breaks

    ),
    aggregated as (
        -- Create the final table : one row per fiche X school X year X sequence of
        -- absences
        select
            school_year,
            fiche,
            id_eco,
            absence_sequence_id,
            min(date_evenement) as absence_start_date,
            max(date_evenement) as absence_end_date,
            max(day_id) - min(day_id) + 1 as absences_sequence_length
        from sequences
        group by school_year, fiche, id_eco, absence_sequence_id

    -- Add final dimensions 
    )

select
    src.school_year,
    src.fiche,
    eco.eco,
    src.absence_sequence_id,
    src.absence_start_date,
    src.absence_end_date,
    src.absences_sequence_length
from aggregated as src
left join {{ ref("i_gpm_t_eco") }} as eco on src.id_eco = eco.id_eco
