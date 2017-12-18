all: final.csv final_noise.csv final_noise_with_dow.csv

clean:
	rm features.csv complaints_by_date.csv perc_noise_by_date.csv final.csv final_noise.csv final_noise_with_dow.csv

311_Service_Requests.csv.gz:
	wget -O - 'https://data.cityofnewyork.us/api/views/erm2-nwe9/rows.csv?accessType=DOWNLOAD' | gzip > 311_Service_Requests.csv.gz &

weather_data.csv:
	wget 'https://www.ncei.noaa.gov/orders/cdo/1131580.csv' -O weather_data.csv

features.csv: weather_data.csv construct_features.awk
	echo "date,avg_temp,daylight_hours,bad_weather,hours_overcast" > features.csv
	./construct_features.awk | sort >> features.csv

complaints_by_date.csv: 311_Service_Requests.csv.gz count_complaints_by_date.awk
	echo "date,complaint_type,count" > complaints_by_date.csv
	./count_complaints_by_date.awk | sort >> complaints_by_date.csv

perc_noise_by_date.csv: 311_Service_Requests.csv.gz compute_perc_noise_by_date.awk
	echo "date,noise_complaints,other_complaints,total" > perc_noise_by_date.csv
	./compute_perc_noise_by_date.awk | sort >> perc_noise_by_date.csv

dow.csv: perc_noise_by_date.csv
	echo "date,day_of_week" > dow.csv
	cat perc_noise_by_date.csv | ./get_day_of_week.awk >> dow.csv

final.csv: features.csv complaints_by_date.csv
	join --header -1 1 -2 1 -t',' features.csv complaints_by_date.csv > final.csv

final_noise.csv: features.csv perc_noise_by_date.csv
	join --header -1 1 -2 1 -t',' features.csv perc_noise_by_date.csv > final_noise.csv

final_noise_with_dow.csv: final_noise.csv dow.csv
	join --header -1 1 -2 1 -t',' final_noise.csv dow.csv > final_noise_with_dow.csv 
