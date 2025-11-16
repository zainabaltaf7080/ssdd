#!/bin/bash

# Load config
source config.cfg

# Track previous checksum
PREV_CHECKSUM=""

while true; do
    CURRENT_CHECKSUM=$(find "$MONITOR_TARGET" -type f -exec sha256sum {} \; | sha256sum)

    if [ "$CURRENT_CHECKSUM" != "$PREV_CHECKSUM" ]; then
        echo "Change detected. Committing..."

        cd "$REPO_PATH"

        git add .
        git commit -m "Auto-commit: changes detected"
        
        if git push $GIT_REMOTE $GIT_BRANCH; then
            echo "Git push successful."

            # Send notification email
            curl --request POST \
              --url https://api.sendgrid.com/v3/mail/send \
              --header "Authorization: Bearer $SENDGRID_API_KEY" \
              --header "Content-Type: application/json" \
              --data '{
                "personalizations": [
                  {
                    "to": [
                      {"email": "'$COLLAB_EMAILS'"}
                    ],
                    "subject": "Repository Update Notification"
                  }
                ],
                "from": {"email": "'$SENDGRID_FROM_EMAIL'"},
                "content": [
                  {
                    "type": "text/plain",
                    "value": "Changes were detected and pushed automatically."
                  }
                ]
              }'
        else
            echo "Git push failed!"
        fi

        PREV_CHECKSUM="$CURRENT_CHECKSUM"
    fi

    sleep 3
done
