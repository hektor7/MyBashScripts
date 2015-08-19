# MyBashScripts
Repo to save my custom bash scripts...

## List of scripts:

### backup
This script creates a simple local backup, taking into account that my laptop could be connected to the external drive... or not.
This script can be executed by cron.

### pomodoro
This script is a simple implementation of pomodoro method to work.
Pomodoro's script can be invoked in two ways. On the one hand you can execute '$ pomodoro "Task to do message"' in order to dedicate 25 minutes to work in the task and 5 minutes for resting (default behaviour). On the other hand you can execute '$ pomodoro 30 5 "Message about task to do"' in order to dedicate 30 minutes to work and 5 to resting.

### box_backup.sh
This script allow you to create a backup of your photos in box.com service in a secure way. This script accesses to your photos, compress them, encrypt them (with GPG), split them and then upload all to box.com service.
