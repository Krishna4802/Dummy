WHERE 
    (
        Medicalinsurancenumber IS NOT NULL
        OR (
            Medicalinsurancenumber IS NULL
            AND Medicalgroupnumber IS NOT NULL
        )
        OR (
            Medicalinsurancenumber IS NULL
            AND Medicalgroupnumber IS NULL
            AND PBMGroupNumber IS NOT NULL
        )
    )
AND
    (
        ( Medicalinsurancenumber IS NOT NULL)
        OR ( Medicalinsurancenumber IS NULL AND Medicalgroupnumber IS NOT NULL)
        OR ( Medicalinsurancenumber IS NULL AND GrandParentName IS NULL AND PBMGroupNumber IS NOT NULL)
    )
    
