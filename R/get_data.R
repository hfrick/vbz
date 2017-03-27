## passenger data from https://data.stadt-zuerich.ch/dataset/vbz-fahrgastzahlen-ogd

download.file(url = "https://data.stadt-zuerich.ch/dataset/vbz_fahrgastzahlen_ogd/resource/ea1e9d1e-e447-49b1-bf51-b8f1e5819bf3/download/reisende.csv", destfile = "../data/reisende.csv")
download.file(url = "https://data.stadt-zuerich.ch/dataset/vbz_fahrgastzahlen_ogd/resource/def17937-f727-4950-adcb-e2d1cde3451a/download/linie.csv", destfile = "../data/linie.csv")
download.file(url = "https://data.stadt-zuerich.ch/dataset/vbz_fahrgastzahlen_ogd/resource/8f0ab824-5942-4159-bf2c-ea0cf7dd00b8/download/haltestellen.csv", destfile = "../data/haltestellen.csv")
download.file(url = "https://data.stadt-zuerich.ch/dataset/vbz_fahrgastzahlen_ogd/resource/4c4201b6-0182-46e1-a0eb-4acc135b1511/download/tagtyp.csv", destfile = "../data/tagtyp.csv")

## additional info on stops from https://data.stadt-zuerich.ch/dataset/vbz-fahrzeiten-ogd

download.file(url = "https://data.stadt-zuerich.ch/dataset/vbz_fahrzeiten_ogd/resource/c1b38f60-2bad-4cf9-9171-7feacf65ad08/download/haltestelle.csv", destfile = "../data/haltestelle.csv")
download.file(url = "https://data.stadt-zuerich.ch/dataset/vbz_fahrzeiten_ogd/resource/fbe8467a-01eb-46cd-aede-612d6fe7118c/download/haltepunkt.csv", destfile = "../data/haltepunkt.csv")
