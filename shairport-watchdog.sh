# find service pids
pgrep shairport

#if we get no pids, service is not running

if [ $? -ne 0 ]
then
 service shairport start
 echo "shairport started or restarted."
fi
