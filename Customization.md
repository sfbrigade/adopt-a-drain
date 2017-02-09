
# Forking Adopt a drain 


The open source code is Comment paragraph
Comment paragraph
Just go through the directories in here and update them for your city with the files or information that you have. 

1. Change the **__title__** for the html page


2. Update **every image** and **image directory** in this directory for: 
a). The logo you'll be using for your app
b). Corporate sponsers (uses bootstrap column system.)
/app/assets/images/logos/
adopt-a-drain/app/views/main/index.html.haml
adopt-a-drain/app/views/main/unauthenticated.html.haml



3. Locales is the directory for different languages available for the project. Update the files inside this directory to the city that you're currently using.
i.e: city_state: "Durham, NC" to city_state: "Oklahoma City, OK"
adopt-a-drain/config/locales/


4. Then you update these all of these entries to reflect the city you're using 
(Email, state, city, etc)

 adopt-a-drain/app/views/main/index.html.haml

 adopt-a-drain/app/views/main/unauthenticated.html.haml
 
 adopt-a-drain/app/views/thing_mailer/first_adoption_confirmation.html.erb

 adopt-a-drain/app/views/thing_mailer/second_adoption_confirmation.html.erb

 adopt-a-drain/app/views/thing_mailer/third_adoption_confirmation.text.erb

 adopt-a-drain/app/views/sidebar/_background.html.haml

 adopt-a-drain/app/views/sidebar/_guidelines.html.haml

 adopt-a-drain/app/views/sidebar/_tos.html.haml

 adopt-a-drain/app/mailers/application_mailer.rb

 adopt-a-drain/config/locales/


5. Change receiving email for web app 
adopt-a-drain/app/mailers/application_mailer.rb


6. The final thing you do is update the gis file for your city


7. Then verify that everything is correct and then deploy the app in your web server and hosting company. 


If you have any complaints, please email or contact us:

SFdrain : info@sfwater.com

Dane Summers : dsummersl@gmail.com

Mario Jimenez : marotjimenez@gmail.com
