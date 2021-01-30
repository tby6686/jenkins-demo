#!/usr/bin/env bash

env=$1
port=$2
projectName=$3

health_url="http://127.0.0.1:$port/sjpt/actuator/health"

echo "env = "$env

pid=`ps -ef | grep java | grep $projectName | grep $port | awk '{print $2}'`
if [ -n "$pid" ]; then
	kill -9 $pid
	sleep 3
fi

case $env in
	sit)
		JAVA_OPTS="-Xms1024m -Xmx1024m -Xss256m -Xmn256m -XX:MetaspaceSize=512m -XX:MaxMetaspaceSize=512m -XX:SurvivorRatio=8"
		JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:../gc.log"
		JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=../dump"
		JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=$env -Dserver.port=$port"
		nohup java -jar $JAVA_OPTS ../$projectName-application/target/$projectName*.jar > ../$projectName.log &
	;;
	dev | local)
		JAVA_OPTS="-Xms1024m -Xmx1024m -Xss256m -Xmn256m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:SurvivorRatio=8"
		JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:../gc.log"
		JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=../dump"
		JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=$env -Dserver.port=$port"
		nohup java -jar $JAVA_OPTS ../$projectName-application/target/$projectName*.jar > ../$projectName.log &
	;;
	uat)
		JAVA_OPTS="-Xms1024m -Xmx1024m -Xss256m -Xmn256m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=128m -XX:SurvivorRatio=8"
		JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/home/logs/$projectName-$env/gc.log"
		JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/logs/$projectName-$env/dump"
		JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=$env -Dserver.port=$port"
		nohup java -jar $JAVA_OPTS ../$projectName-application/target/$projectName*.jar > ../$projectName.log &
	;;
	prod)
		JAVA_OPTS="-Xms4096m -Xmx4096m -Xss256m -Xmn256m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:SurvivorRatio=8"
		JAVA_OPTS="$JAVA_OPTS -XX:+UseConcMarkSweepGC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/home/logs/$projectName-$env/gc.log"
		JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/logs/$projectName-$env/dump"
		JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=$env -Dserver.port=$port"
		nohup java -jar $JAVA_OPTS ../$projectName-application/target/$projectName*.jar > ../$projectName.log &
	;;
	*)
		echo "No this env:$env."
		exit 1
	;;
esac


function getJsonValuesByAwk() {
    awk -v json="$1" -v key="$2" -v defaultValue="$3" 'BEGIN{
        foundKeyCount = 0
        while (length(json) > 0) {
            # pos = index(json, "\""key"\""); ## 这行更快一些，但是如果有value是字符串，且刚好与要查找的key相同，会被误认为是key而导致值获取错误
            pos = match(json, "\""key"\"[ \\t]*?:[ \\t]*");
            if (pos == 0) {if (foundKeyCount == 0) {print defaultValue;} exit 0;}

            ++foundKeyCount;
            start = 0; stop = 0; layer = 0;
            for (i = pos + length(key) + 1; i <= length(json); ++i) {
                lastChar = substr(json, i - 1, 1)
                currChar = substr(json, i, 1)

                if (start <= 0) {
                    if (lastChar == ":") {
                        start = currChar == " " ? i + 1: i;
                        if (currChar == "{" || currChar == "[") {
                            layer = 1;
                        }
                    }
                } else {
                    if (currChar == "{" || currChar == "[") {
                        ++layer;
                    }
                    if (currChar == "}" || currChar == "]") {
                        --layer;
                    }
                    if ((currChar == "," || currChar == "}" || currChar == "]") && layer <= 0) {
                        stop = currChar == "," ? i : i + 1 + layer;
                        break;
                    }
                }
            }

            if (start <= 0 || stop <= 0 || start > length(json) || stop > length(json) || start >= stop) {
                if (foundKeyCount == 0) {print defaultValue;} exit 0;
            } else {
                print substr(json, start, stop - start);
            }

            json = substr(json, stop + 1, length(json) - stop)
        }
    }'
}


sleep 20
for ((i=0;i<20;i++))
do
	curl -s ${health_url} > health
	state=`cat health`
	status=`getJsonValuesByAwk "$state" "status" "DOWN"|head -1`
	if [ $status = "\"UP\"" ]; then
		break
	else
		echo "Waiting for start ..."
		sleep 5
	fi
done
if [ $status = "\"UP\"" ]; then
	echo "Deploy success"
	exit 0
else
	echo "Deploy Fail"
	exit 1
fi
	
	