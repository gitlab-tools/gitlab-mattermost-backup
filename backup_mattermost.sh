#!/bin/bash

currDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
confFile="$currDir/backup_mattermost.conf"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# conffile
if [ -e $confFile -a -r $confFile ]
then
    source $confFile
else
    echo "$confFile not found."
    exit 1
fi

# prepare
rm -rf $gitlabBackupDir/mattermost
mkdir -p $gitlabBackupDir/mattermost/data

# backup data
cp -R $mattermostDir/* $gitlabBackupDir/mattermost/data
# backup postgres
su - mattermost -c "/opt/gitlab/embedded/bin/pg_dump -U gitlab_mattermost -h /var/opt/gitlab/postgresql -p 5432 mattermost_production" > $gitlabBackupDir/mattermost/mattermost_production_backup.sql

# package and cleanup
backupfile=$(date +%s_%Y_%m_%d)_mattermost_backup.tar.gz
tar -zcf $gitlabBackupDir/$backupfile $gitlabBackupDir/mattermost
rm -rf $gitlabBackupDir/mattermost

# upload to S3
$awscli s3 cp $gitlabBackupDir/$backupfile $s3path
rm -f $gitlabBackupDir/$backupfile