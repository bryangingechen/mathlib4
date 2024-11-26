#!/usr/bin/env python3
import sys
import zulip
import re

# Usage:
# python scripts/zulip_emoji_merge_delegate.py $ZULIP_API_KEY $ZULIP_EMAIL $ZULIP_SITE $LABEL $PR_NUMBER
# See .github/workflows/zulip_emoji_merge_delegate.yaml for the meaning of these variables

ZULIP_API_KEY = sys.argv[1]
ZULIP_EMAIL = sys.argv[2]
ZULIP_SITE = sys.argv[3]
LABEL = sys.argv[4]
PR_NUMBER = 18679 #sys.argv[5]

print(f"LABEL: '{LABEL}'")
print(f"PR_NUMBER: '{PR_NUMBER}'")

# Initialize Zulip client
client = zulip.Client(
    email=ZULIP_EMAIL,
    api_key=ZULIP_API_KEY,
    site=ZULIP_SITE
)

print(f"Searching for 'https://github.com/leanprover-community/mathlib4/pull/{PR_NUMBER}'")
# Fetch the last 200 messages
response = client.get_messages({
    "anchor": "newest",
    "num_before": 200,
    "num_after": 0,
    "narrow": [{"operator": "channel", "operand": "PR reviews"}],
})

messages = response['messages']

pr_pattern = re.compile(f'https://github.com/leanprover-community/mathlib4/pull/{PR_NUMBER}')

for message in messages:
    content = message['content']
    match = pr_pattern.search(content)
    if match:
        print(f"matched: '{message}'")

        # removing previous emoji reactions
        print('Removing peace_sign')
        result = client.remove_reaction({
            "message_id": message['id'],
            "emoji_name": "peace_sign"
        })
        print(f"result: '{result}'")
        print('Removing bors')
        result = client.remove_reaction({
            "message_id": message['id'],
            "emoji_name": "bors"
        })
        print(f"result: '{result}'")

        print('Removing merge')
        result = client.remove_reaction({
            "message_id": message['id'],
            "emoji_name": "merge"
        })
        print(f"result: '{result}'")

        # applying appropriate emoji reaction
        if 'delegated' == LABEL:
            print('adding delegated')
            client.add_reaction({
                "message_id": message['id'],
                "emoji_name": "peace_sign"
            })
        elif 'ready-to-merge' == LABEL:
            print('adding ready-to-merge')
            client.add_reaction({
                "message_id": message['id'],
                "emoji_name": "bors"
            })
        elif LABEL.startswith("[Merged by Bors]"):
            print('adding [Merged by Bors]')
            client.add_reaction({
                "message_id": message['id'],
                "emoji_name": "merge"
            })
