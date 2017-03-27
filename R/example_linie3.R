library("dplyr")
library("ggplot2")
library("ggmap")
library("leaflet")

## read passenger data
reisende <- read.csv(file = "../data/reisende.csv", sep = ";",
                     stringsAsFactors = FALSE)
names(reisende) <- tolower(names(reisende))

tagtyp <- read.csv(file = "../data/tagtyp.csv", sep = ",", stringsAsFactors = FALSE)
names(tagtyp) <- tolower(names(tagtyp))

haltestellen <- read.csv(file = "../data/haltestellen.csv", sep = ",",
                     stringsAsFactors = FALSE)
names(haltestellen) <- tolower(names(haltestellen))

linie <- read.csv("../data/linie.csv", sep = ",", stringsAsFactors = FALSE)
names(linie) <- tolower(names(linie))

## read additional data (info on stops from delay data)
haltepunkt <- read.csv(file = "../data/haltepunkt.csv", sep = ",",
                      stringsAsFactors = FALSE)
names(haltepunkt) <- tolower(names(haltepunkt))
haltepunkt <- haltepunkt %>% mutate(gps_longitude = as.numeric(gsub(",", ".", gps_longitude)),
                                    gps_latitude = as.numeric(gsub(",", ".", gps_latitude)),
                                    halt_punkt_ist_aktiv = halt_punkt_ist_aktiv == "True")

haltestelle <- read.csv(file = "../data/haltestelle.csv", sep = ",",
                      stringsAsFactors = FALSE)
names(haltestelle) <- tolower(names(haltestelle))
haltestelle <- haltestelle %>% mutate(halt_ist_aktiv = halt_ist_aktiv == "True")

halt <- full_join(haltepunkt, haltestelle)


## combine data sets
reisende <- left_join(reisende, tagtyp)
reisende <- left_join(reisende, haltestellen)
reisende <- left_join(reisende, linie)


## data prep:
## id_abschnitt_kr: id_abschnitt without the direction info
## id_abschnitt_kr_linie: id_abschnitt without the direction info but with line info
## hour: hour of the trip
## net_einsteiger: einsteiger - aussteiger
reisende <- reisende %>%
    mutate(id_abschnitt_kr = ifelse(richtung == 1,
                                    paste(haltestellen_id, nach_hst_id, sep = "_"),
                                    paste(nach_hst_id, haltestellen_id, sep = "_")),
           id_abschnitt_kr_linie = ifelse(richtung == 1,
                                          paste(linien_id, haltestellen_id, nach_hst_id, sep = "_"),
                                          paste(linien_id, nach_hst_id, haltestellen_id, sep = "_")),
           hour_ch = sapply(strsplit(fz_ab, ":"), function(x) x[1]),
           hour_num = as.numeric(hour_ch),
           net_einsteiger = einsteiger - aussteiger)
## passagiere: number of passengers on the tram/bus
reisende <- reisende %>% group_by(plan_fahrt_id) %>% arrange(sequenz) %>%
    mutate(passagiere = cumsum(net_einsteiger)) %>% ungroup() 






## example: pick a single line (Linie 3)
example_id <- linie$linien_id[linie$linienname_fahrgastauskunft == "3"]
exampleline <- filter(reisende, linien_id == example_id)
## use data from regular weekdays
exampleline <- filter(exampleline, tagtyp_id == 6)




## get number of passengers for a segment (direction does not matter) for a specified window of time

## specify time window
time_start <- 9
time_end <- 11
exampleline <- exampleline %>% mutate(zeitfenster = time_start <= hour_num & hour_num < time_end)

## average number of passengers over the selected time period
totalpassengers <- exampleline %>% filter(zeitfenster) %>%
    group_by(id_abschnitt_kr) %>% summarise(passagiere = sum(passagiere))



## get GPS coordinates for each haltestelle (haltepunkt) on the line

## recover info on stops
totalpassengers <- totalpassengers %>%
    mutate(halt_von = as.numeric(sapply(strsplit(id_abschnitt_kr, "_"), function(x) x[1])),
           halt_nach = as.numeric(sapply(strsplit(id_abschnitt_kr, "_"), function(x) x[2])))

## get GPS coordinates for each stop
## halt_von and halt_nach are "haltestellen_id" in haltestellen
## haltestellen can be joined with halt via "haltestellenlangname" =  "halt_lang"
haltcombined <- left_join(haltestellen, halt, c("haltestellenlangname" = "halt_lang"))

## pick a haltepunkt for each haltestelle
## README: improve this to "pick the right haltepunkt"
haltaktiv <- haltcombined %>% filter(halt_punkt_ist_aktiv) %>%
    group_by(haltestellen_id) %>% slice(1)

haltvon <- haltaktiv %>% select(haltestellen_id, gps_longitude, gps_latitude) %>%
    rename(gps_longitude_von = gps_longitude,
           gps_latitude_von = gps_latitude)
haltnach <- haltaktiv %>% select(haltestellen_id, gps_longitude, gps_latitude) %>%
    rename(gps_longitude_nach = gps_longitude,
           gps_latitude_nach = gps_latitude)

totalpassengers <- left_join(totalpassengers, haltvon, c("halt_von" = "haltestellen_id"))
totalpassengers <- left_join(totalpassengers, haltnach, c("halt_nach" = "haltestellen_id"))


## plot on a map

## README: needs to be improved - ref values from max(day total of all lines)?
totalpassengers <- totalpassengers %>%
    mutate(plwd = (passagiere - min(passagiere, na.rm = TRUE)) /
               (max(passagiere, na.rm = TRUE) - min(passagiere, na.rm = TRUE)))

map <- get_map(geocode("Zurich, CH"), zoom = 13, source = "stamen", maptyp = "toner-lite")

           
## plot stops
ggmap(map) + geom_point(data = totalpassengers, mapping = aes(x = gps_longitude_von, y = gps_latitude_von), colour = "red")

## plot line
ggmap(map) + geom_segment(mapping = aes(x = gps_longitude_von, xend = gps_longitude_nach,
                                        y = gps_latitude_von, yend = gps_latitude_nach,
                                        lwd = plwd),
                          data = totalpassengers, col = "darkgreen")
##png("../figure/linie3_9-11.png", width = 1052, height = 1052)
ggmap(map) + geom_segment(mapping = aes(x = gps_longitude_von, xend = gps_longitude_nach,
                                        y = gps_latitude_von, yend = gps_latitude_nach,
                                        colour = passagiere),
                          data = totalpassengers, lwd = 2)
##dev.off()

## leaflet line (no info on passenger numbers)
tp <- totalpassengers %>% arrange(gps_longitude_von)
l <- leaflet() %>% addTiles() %>% addProviderTiles(providers$CartoDB.Positron) %>%
    addMarkers(lng = tp$gps_longitude_von, lat = tp$gps_latitude_von) %>%
    addPolylines(lng = tp$gps_longitude_von, lat = tp$gps_latitude_von)
l
