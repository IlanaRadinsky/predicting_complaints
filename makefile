all: 311_Service_Requests.csv.gz weather_data.csv

311_Service_Requests.csv.gz:
	wget -O - 'https://data.cityofnewyork.us/api/views/erm2-nwe9/rows.csv?accessType=DOWNLOAD' | gzip > 311_Service_Requests.csv.gz &

weather_data.csv:
	wget 'https://www.ncei.noaa.gov/orders/cdo/1131580.csv' -O weather_data.csv

gloominess_index.csv:
	./construct_gloominess_index.awk
