######################
docker run -p 8001:8001 --name eureka-server \
-v /etc/localtime:/etc/localtime \
-v /mydata/app/eureka-server/logs:/var/logs \
-d eureka-server:0.0.1-SNAPSHOT
#####################
#!/usr/bin/env bash
app_name='eureka-server'
port='8001'
docker stop ${app_name}
echo '----stop container----'
docker rm ${app_name}
echo '----rm container----'
docker run -p ${port}:${port} --name ${app_name} \
-v /etc/localtime:/etc/localtime \
-v /mydata/app/${app_name}/logs:/var/logs \
-d ${app_name}:0.0.1-SNAPSHOT
echo '----start container----'
