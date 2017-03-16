#!/usr/bin/env sh

errors=0
if [ -z "$S3_BUCKET" ]; then
    echo "Environment variable S3_BUCKET has not been defined."
    errors=1
else
    aws s3 ls s3://$S3_BUCKET > /dev/null
    if [ $? -ne 0 ]; then
        errors=1
    fi
fi
if [ -z "$BACKUP_PATH" ]; then
    echo "Environment variable BACKUP_PATH has not been defined."
    errors=1
fi

if [ $errors -eq 1 ]; then
    echo
    exit
fi

#### Configuring defaults
if [ -z "$AWS_DEFAULT_REGION" ]; then
    export AWS_DEFAULT_REGION='us-west-2'
fi
if [ ! -z "$TIMEZONE" ]; then
    ### Default time set at the container level to America/Los_Angeles
    echo $TIMEZONE > /etc/localtime
fi

#### Interval Settings
if [ -z "$BACKUP_PERIOD_HOURS" ]; then
    BACKUP_PERIOD_HOURS=24
fi
if [ -z "$BACKUP_START_DAY" ]; then
    BACKUP_START_DAY=0
fi
if [ -z "$BACKUP_START_HOUR" ]; then
    BACKUP_START_HOUR=0
fi
if [ -z "$RANDOM_INTERVAL_MIN" ]; then
    RANDOM_INTERVAL_MIN=20
fi

echo "S3BACKUP CONFIGURATION:"
echo "   S3_BUCKET=$S3_BUCKET"
echo "   S3_PREFIX=$S3_PREFIX"
echo "   BACKUP_PATH=$BACKUP_PATH"
echo "   AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION"
echo "   TIMEZONE=$(date +%Z)"
echo "   RANDOM_INTERVAL_MIN=$RANDOM_INTERVAL_MIN"
echo "   BACKUP_PERIOD_HOURS=$BACKUP_PERIOD_HOURS"
echo "   BACKUP_START_DAY=$BACKUP_START_DAY  (Note: Not yet implemented)"
echo "   BACKUP_START_HOUR=$BACKUP_START_HOUR"


##date


timetosleep()
{
    now=$(date +'%Y-%m-%d %H:%M:%S')
    CURRENT_HOUR=$(date --date="$now" +'%H')
    CURRENT_MINUTE=$(date --date="$now" +'%M')
    CURRENT_SECOND=$(date --date="$now" +'%S')
    ss=$(expr 60 - $CURRENT_SECOND)
    mm=$(expr 59 - $CURRENT_MINUTE)

    hh=$BACKUP_START_HOUR
    while [ ! $hh -gt $CURRENT_HOUR ]
    do
        hh=$(expr $hh + $BACKUP_PERIOD_HOURS)
    done
    hh=$(expr $hh - $CURRENT_HOUR - 1)

    rr=$(awk -v min=0 -v max=$RANDOM_INTERVAL_MIN 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')

    formula="$ss+$mm*60+$hh*3600+$rr*60"
    SECONDS_TO_SLEEP=$(echo $formula | bc)
    echo "$(date) - Sleeping for $hh:$mm:$ss + $rr random min...   or exactly $SECONDS_TO_SLEEP seconds."
    sleep ${SECONDS_TO_SLEEP}s
}


bucketlocation="s3://$S3_BUCKET"
if [ ! -z "$S3_PREFIX" ]; then
    bucketlocation=${bucketlocation}/$S3_PREFIX/
else
    bucketlocation=${bucketlocation}/
fi
echo "   BACKUP_LOCATION=$bucketlocation"
echo

LAST_BACKUP_FILE=''
while :
do
    if [ ! -z "$LAST_BACKUP_FILE" ]; then
        rm $LAST_BACKUP_FILE
    fi
    filename='backup-'$(date +'%Y-%m-%d-%H%M%S').tar.gz
    cd $BACKUP_PATH
    cd ..
    basename=$(basename $BACKUP_PATH)
    echo tar -czf /tmp/$filename $basename
    tar -czf /tmp/$filename $basename
    aws s3 cp /tmp/$filename ${bucketlocation}

    LAST_BACKUP_FILE=/tmp/$filename

    timetosleep
done
