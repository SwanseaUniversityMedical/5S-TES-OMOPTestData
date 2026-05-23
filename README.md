
## Whats this repo do

1. produces synthetic data and load it to postgres
2. take the synthetic data and produce an OMOP version of it

### Contents

- Synthea-Docker : create synthetic data to OUTPUT directory
- Synthea-Load_Docker
    - Creates a a postgres database
    - Loads the synthetic data to postgres
    - Create an OMOP version from this database into same database
- Vocabulary: used to map synthetic data to OMOP
- Openmetadata : openmetadata to provide a catalogue of this database


### Steps
1. Create synthetic OMOP data into CSV
2. Run loader and synthetci data generator

