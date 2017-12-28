all: final_plot_1.pdf final_plot_2.pdf final_plot_3.pdf

clean:
	rm weather_features.csv weather_features_with_gloominess.csv noise_complaints_by_date.csv dow.csv final_noise.csv final_noise_with_dow.csv final_plot_1.pdf final_plot_2.pdf

311_Service_Requests.csv.gz:
	wget -O - 'https://data.cityofnewyork.us/api/views/erm2-nwe9/rows.csv?accessType=DOWNLOAD' | gzip > 311_Service_Requests.csv.gz &

weather_features.csv: weather_data.csv construct_weather_features.awk
	echo "date,avg_temp,daylight_hours,bad_weather,hours_overcast" > weather_features.csv
	gawk -f construct_weather_features.awk | sort >> weather_features.csv

weather_features_with_gloominess.csv: weather_features.csv construct_gloominess_index.awk
	echo "date,avg_temp,daylight_hours,bad_weather,hours_overcast,gloomy_today,gloomy_past_two_days,gloomy_past_three_days" > weather_features_with_gloominess.csv
	gawk -f construct_gloominess_index.awk >> weather_features_with_gloominess.csv

noise_complaints_by_date.csv: 311_Service_Requests.csv.gz count_noise_complaints_by_date.awk
	echo "date,noise_complaints,other_complaints,total" > noise_complaints_by_date.csv
	gawk -f count_noise_complaints_by_date.awk | sort >> noise_complaints_by_date.csv

dow.csv: noise_complaints_by_date.csv get_day_of_week.awk
	echo "date,day_of_week" > dow.csv
	cat noise_complaints_by_date.csv | gawk -f get_day_of_week.awk >> dow.csv

final_noise.csv: weather_features_with_gloominess.csv noise_complaints_by_date.csv
	join --header -1 1 -2 1 -t',' weather_features_with_gloominess.csv noise_complaints_by_date.csv > final_noise.csv

final_noise_with_dow.csv: final_noise.csv dow.csv
	join --header -1 1 -2 1 -t',' final_noise.csv dow.csv > final_noise_with_dow.csv 

final_plot_1.pdf final_plot_2.pdf final_plot_3.pdf: final_noise_with_dow.csv noise_model.R model_evaluation.R
	Rscript noise_model.R
