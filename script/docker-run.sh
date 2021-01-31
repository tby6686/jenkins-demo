######################
## docker run -p 8001:8001 --name eureka-server \
## -v /etc/localtime:/etc/localtime \
## -v /mydata/app/eureka-server/logs:/var/logs \
## -d eureka-server:0.0.1-SNAPSHOT
#####################
#!/usr/bin/env bash

app_name=$1
port=$2
version=$3

#!/usr/bin/env bash
docker stop ${app_name}
echo '----stop container----'
docker rm ${app_name}
echo '----rm container----'
docker run -p ${port}:${port} --name ${app_name} \
-v /etc/localtime:/etc/localtime \
-v /mydata/app/${app_name}/logs:/var/logs \
-d ${app_name}:${version}
echo '----start container----'
