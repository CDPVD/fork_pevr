select distinct ele.code_perm, eco.id_eco, eco.annee
from {{ ref("i_gpm_e_dan") }} as eledan
left join {{ ref("i_gpm_t_eco") }} as eco on eledan.id_eco = eco.id_eco
left join {{ ref("i_gpm_e_ele") }} as ele on eledan.fiche = ele.fiche
where
    eledan.statut_don_an = 'A'
    and eco.eco not in ('069', '099', '901', '902', '903')  -- Ignore les élèves en cours d'été
    and eco.eco not in ('960')  -- Ignore les élèves qui sont inscrits à l'école virtuelle
    and eco.eco not in ('950')  -- Ignore les élèves hors territoire qui sont dans le processus de demande d'inscription dans une école du CSS
    and eledan.ordre_ens = '4'
    and lower(eledan.dist) in (
        'g1',
        'g2',
        'g2c',
        'g3',
        'g3a',
        'g4',
        'g4a',
        'g5',
        'g6',
        'xf1',
        'xf2',
        'xfp',
        'sfp'
    )
    and (eledan.grp_rep not in ('999') or eledan.grp_rep is null)  -- Ignore l'enseignement réalisé à la maison par les parents #}
