
echo "Configure LD PATH ..."

export LD_LIBRARY_PATH=$PWD/lib
#export LD_LIBRARY_PATH=/oem/lib:${LD_LIBRARY_PATH}


echo $LD_LIBRARY_PATH

echo "Configure OK"

echo "app name" $1

chmod 775 $1

counter=$#

echo "argv couter:$counter"
if [ $counter -eq 0 ];then
    echo "usage:./run_app.sh app_name argv[0] argv[1] ....."
    exit Failure
fi

argvs=$@ #get all param
echo "cmd: ./$argvs"

./$argvs
