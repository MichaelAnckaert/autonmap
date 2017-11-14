#!/bin/bash
# autonmap - https://github.com/MichaelAnckaert/autonmap
# Original source https://github.com/lozzd/AutoNmap
# Updated by Michael Anckaert <michael.anckaert@sinax.be>

DATE=`date +%F-%s`

## Begin Config

# The directory for autonmap data/scans
RUN_DIRECTORY="/root/autonmap/"

# The directory you want the web report to live in
WEB_DIRECTORY="/var/www/scans/"

# The full base path (http) to where the report will be hosted by your 
# webserver. I suggest setting up auth using htpasswd etc, in which case 
# you can include the auth in the URL for simplicity if you want. 
WEB_URL="https://garden.sinax.be/scans/"

# The full path to your chosen nmap binary
NMAP="/usr/bin/nmap"

# The path to the ndiff tool provided with nmap
NDIFF="/usr/bin/ndiff"

# The email address(es), space seperated that you wish to send the email report to. 
EMAIL_RECIPIENTS="michael@sinax.be"

## End config

echo "`date` - Welcome to AutoNmap2. "

# Ensure we can change to the run directory
cd $RUN_DIRECTORY || exit 2

for target_list in targets/*.list; do
	TARGET=`echo $target_list | cut -d '/' -f2 | cut -d '.' -f1`
	CURRENT_SCAN=scan-$DATE.xml
	SCAN_DIR="scans/$TARGET"
	WEB_DIR="$WEB_DIRECTORY/$TARGET"
	SCAN_FILE=$SCAN_DIR/scan-$DATE.xml
	PREV_SCAN_FILE=$SCAN_DIR/scan-prev.xml

	mkdir -p $WEB_DIR
	mkdir -p $SCAN_DIR

	echo "`date` - Running nmap for target $TARGET, please wait. This may take a while.  "
	$NMAP --open -T4 -PN -iL $target_list -n -oX $SCAN_FILE --stylesheet "../nmap.xsl" > /dev/null
	echo "`date` - Nmap process completed with exit code $?"

	# If this is not the first time autonmap2 has run, we can check for a diff. Otherwise skip this section, and tomorrow when the link exists we can diff.
	if [ -e $PREV_SCAN_FILE ]
	then
	    echo "`date` - Running ndiff..."
	    # Run ndiff with the link to yesterdays scan and todays scan
	    DIFF=`$NDIFF $PREV_SCAN_FILE $SCAN_FILE`

	    echo "`date` - Checking ndiff output"
	    # There is always two lines of difference; the run header that has the time/date in. So we can discount that.
	    if [ `echo "$DIFF" | wc -l` -gt 2 ]
	    then
		    echo "`date` - Differences Detected. Sending mail."
		    echo -e "AutoNmap2 found differences in a scan for '$TARGET' since last time. \n\n$DIFF\n\nFull report available at $WEB_URL" | mail -s "AutoNmap2" $EMAIL_RECIPIENTS
	    else
		    echo "`date`- No differences, skipping mail. "
	    fi

	else 
	    echo "`date` - There is no previous scan (scan-prev.xml). Cannot diff now; will do so next time."
	fi

	# Copy the scan report to the web directory so it can be viewed later.
	echo "`date` - Copying XML to web directory. "
	cp $SCAN_FILE $WEB_DIR

	# Create the link from the current report to scan-prev so it can be used next time for diff.
	echo "`date` - Linking current scan to scan-prev.xml"
	cd $SCAN_DIR
	ln -sf $CURRENT_SCAN scan-prev.xml
	cd $RUN_DIRECTORY
done

echo "`date` - AutoNmap2 is complete."
exit 0 
