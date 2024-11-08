#!/usr/bin/env bash

AUTHOR="${1}"     # adomani
BODY="${2}"       # message content, containing `maintainer {merge, delegate}`
EVENT_NAME="${3}" # one of `issue_comment`, `pull_request_review` or `pull_request_review_comment`
                  # to be converted to `comment`, `review` or `review comment`
PR="${4}"         # the number of the PR
URL="${5}"        # the url link to the PR
PR_TITLE="${6}"   # the title of the PR

mergeOrDelegate="neither merge nor delegate"
if printf '%s\n' "${BODY}" | grep -q "^maintainer merge"
then
  mergeOrDelegate=merge
elif printf '%s\n' "${BODY}" | grep -q "^maintainer delegate"
then
  mergeOrDelegate=delegate
fi

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

GHevent=nothing
#if [ "${EVENT_NAME}" == "comment" ]
#then
#  GHevent=issue
#elif [ "${EVENT_NAME/% */}" == "review" ]
#then
#  GHevent=pull_request
#fi

#printf $'title<<EOF\n${{ format(\'{0} requested a maintainer %s from %s on PR [#{1}]({2}):\', github.event.%s.user.login, github.event.%s.number, github.event.%s.html_url ) }}\nEOF' "${mergeOrDelegate}" "${EVENT_NAME}" "${EVENT_NAME}" "${GHevent}" "${GHevent}"

printf '%s requested a maintainer %s from %s on PR [#%s](%s):\n' "${AUTHOR}" "${mergeOrDelegate}" "${SOURCE}" "${PR}" "${URL}"
printf '> %s\n' "${PR_TITLE}"
