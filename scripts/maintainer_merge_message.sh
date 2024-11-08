#!/usr/bin/env bash

AUTHOR="${1}"     # adomani
BODY="${2}"       # message content, containing `maintainer {merge, delegate}`
EVENT_NAME="${3}" # one of `issue_comment`, `pull_request_review` or `pull_request_review_comment`
                  # to be converted to `comment`, `review` or `review comment`
PR="${4}"         # the number of the PR
URL="${5}"        # the url link to the PR
PR_TITLE="${6}"   # the title of the PR

# figure out if the message contains `maintainer merge` or `maintainer delegate`
# and set the `mergeOrDelegate` variable accordingly
mergeOrDelegate="neither merge nor delegate"
if printf '%s\n' "${BODY}" | grep -q "^maintainer merge"
then
  mergeOrDelegate=merge
elif printf '%s\n' "${BODY}" | grep -q "^maintainer delegate"
then
  mergeOrDelegate=delegate
fi

# figure out if the GitHub event starting this action is a comment, a review or a review comment
# and set the `SOURCE` variable accordingly
case ${EVENT_NAME} in
  issue_comment)
  SOURCE='comment'
  ;;
  pull_request_review)
  SOURCE='review'
  ;;
  pull_request_review_comment)
  SOURCE='review comment'
  ;;
  *)
  SOURCE='unknown origin'
  ;;
esac

printf '%s requested a maintainer %s from %s on PR [#%s](%s):\n' "${AUTHOR}" "${mergeOrDelegate}" "${SOURCE}" "${PR}" "${URL}"
printf '> %s\n' "${PR_TITLE}"
