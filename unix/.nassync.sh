#! /bin/bash
NASSYNC_DEST=/home/alex/Documents/it/backups/manjaro
if [ -e $NASSYNC_DEST ];# Only run if destination exists, aka network drive was mounted.
then
	# Flags used:
	# a -- preserve permissions, date modified, groups, ...
	# v -- verbose mode
	# delete -- delete files at the destination that are not found/no longer found in the source. Dangerous command, but if the destination itself is backed up regularly, this should be fine.
	# log-file -- Just a log file at the specified location.
	rsync -av --delete --log-file="$NASSYNC_DEST"/nassync.log /home/alex/.config /home/alex/.ssh /home/alex/Databases $NASSYNC_DEST
	notify-send "Ran sync job."
else
	notify-send "rsync job unsuccessful." "Destination folder ($NASSYNC_DEST) did not exist."
fi

