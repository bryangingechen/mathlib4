#!/usr/bin/env bash

AUTHOR="${1}"     # adomani
M_or_D="${2}"     # `merge` or `delegate`
EVENT_NAME="${3}" # one of `issue_comment`, `pull_request_review` or `pull_request_review_comment`
                  # to be converted to `comment`, `review` or `review comment`
PR="${4}"         # the number of the PR
URL="${5}"        # the url link to the PR
PR_TITLE="${6}"   # the title of the PR

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

printf '%s requested a maintainer %s from %s on PR [#%s](%s):\n' "${AUTHOR}" "${M_or_D}" "${SOURCE}" "${PR}" "${URL}"
printf '> %s\n' "${PR_TITLE}"
