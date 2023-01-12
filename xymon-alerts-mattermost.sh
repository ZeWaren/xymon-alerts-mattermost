#!/bin/sh
# Reference documentation:
# Mattermost documentation -> Webhooks -> Incoming webhooks:
# https://developers.mattermost.com/integrate/webhooks/incoming/

# Mattermost config:
url="[CONFIGURE ME]"
channel="#${RCPT}"

# Variables from Xymon
hostname=$BBHOSTNAME            # The name of the host that the alert is about
service=$BBSVCNAME              # The name of the service that the alert is about
alert_color=$BBCOLORLEVEL       # The color of the alert: "red", "yellow" or "purple"
alert_msg=$BBALPHAMSG           # The full text of the status log triggering the alert
alert_title="$BBHOSTSVC $level" # HOSTNAME.SERVICE that the alert is about.
recovered="$RECOVERED"          # Is "1" if the service has recovered.

# If I'm gonna output a message, mind as well timestamp it.
time_stamp() {
  date +%Y-%m-%d:%H:%M:%S"%R $*"
}

# If the alert is recovered, then we want to display some green instead of the original color:
if [ $RECOVERED -eq 1 ]; then
  alert_color="green"
fi

# Check the color and set Mattermost payload variables.
case $alert_color in
  red)
    emoji=":red_circle:"
    color="danger"
    ;;
  yellow)
    emoji=":warning:"
    color="warning"
    ;;
  green)
    emoji=":ok:"
    color="good" #
    ;;
  purple)
    time_stamp "xymon_to_slack.sh: Received Purple Alert. Ignoring."
    exit
    ;;
esac

# Setup the payload for delivery to Mattermost:
payload=$(cat <<EOF
{
  "channel": "${channel}",
  "username": "${hostname}",
  "icon_emoji": "${emoji}",
  "attachments": [
    {
      "title": "${alert_title}",
      "color": "${color}",
      "text": "${alert_msg}",
      "author_name": "Xymon",
      "fields": [
        {
          "short": true,
          "title": "Host",
          "value":"${hostname}"
	    },
        {
          "short": true,
          "title": "Service",
          "value":"${service}"
	    },
        {
          "short": true,
          "title": "Color",
          "value":"${emoji} ${alert_color}"
	    }
	  ]
    }
  ]
}
EOF
)

# Send the payload to Mattermost:
curl -s -X POST --data-urlencode "payload=${payload}" ${url}