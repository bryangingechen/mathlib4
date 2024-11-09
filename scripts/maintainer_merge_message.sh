#!/usr/bin/env bash

AUTHOR="${1}"     # adomani
COMMENT="${2}"    # the comment on the PR
EVENT_NAME="${3}" # one of `issue_comment`, `pull_request_review` or `pull_request_review_comment`
                  # to be converted to `comment`, `review` or `review comment`
PR_NUMBER="${4}"  # the number of the PR
PR_URL="${5}"     # the url link to the PR
PR_TITLE="${6}"   # the title of the PR

# start by printing out the relevant variables, for debugging
#M_or_D="${{ steps.merge_or_delegate.outputs.mOrD }}"
echo "PR_NUMBER: '${PR_NUMBER:-PR_NUMBER not set}'"
PR_TITLE="${PR_TITLE_ISSUE}${PR_TITLE_PR}"
echo "PR_TITLE: '${PR_TITLE:-PR_TITLE not set}'"
echo "AUTHOR: '${AUTHOR:-AUTHOR not set}'"
#echo "M_or_D: ${M_or_D:-M_or_D not set}"
echo "PR_URL: '${PR_URL:-PR_URL not set}'"
echo "EVENT_NAME: '${EVENT_NAME:-EVENT_NAME not set}'"



# we strip `\r`, since line breaks from GitHub include this character
COMMENT="${COMMENT//$'\r'/}"
# for debugging potential issues, we print a `hexdump` and a "human" form of `COMMENT` to stderr
>&2 printf '%s' "${COMMENT}" | hexdump -cC
>&2 printf 'Comment:"%s"\n' "${COMMENT}"
# here we really find out whether the comment contains `maintainer merge` or `maintainer delegate`
m_or_d="$(printf '%s' "${COMMENT}" |
  sed -n 's=^maintainer  *\(merge\|delegate\)$=\1=p' | head -1)"
>&2 printf $'"maintainer delegate" or "maintainer merge" found? \'%s\'\n' "${m_or_d}"

if [ -z "${m_or_d}" ]
then
  return ''
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

printf '%s requested a maintainer %s from %s on PR [#%s](%s):\n' "${AUTHOR}" "${M_or_D}" "${SOURCE}" "${PR_NUMBER}" "${PR_URL}"
printf '> %s\n' "${PR_TITLE}"
