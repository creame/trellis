#!/bin/bash
shopt -s nullglob

NUM_ARGS=2

ENVIRONMENTS=( hosts/* )
ENVIRONMENTS=( "${ENVIRONMENTS[@]##*/}" )

SITE="$(dirname "$(dirname "$(readlink -f "$0")")")"
SITE=${SITE##*/}

DEPLOY_CMD="ansible-playbook deploy.yml -e env=$2 -e site=$SITE"
UPLOADS_PUSH_CMD="ansible-playbook uploads.yml -i hosts/$2 -e site=$SITE -e mode=push"
UPLOADS_PULL_CMD="ansible-playbook uploads.yml -i hosts/$2 -e site=$SITE -e mode=pull"


show_usage() {
  echo "Usage: do <action> <environment>

<action> is the action to perform (deploy, uploads-push, uploads-pull)
<environment> is the environment to deploy to (staging, production, etc)

Available environments:
`( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )`

Examples:
  ./do.sh deploy staging
  ./do.sh uploads-push production
"
}

HOSTS_FILE="hosts/$2"

[[ $# -ne $NUM_ARGS || $1 = -h ]] && { show_usage; exit 0; }

if [[ ! -e $HOSTS_FILE ]]; then
  echo "Error: $2 is not a valid environment ($HOSTS_FILE does not exist)."
  echo
  echo "Available environments:"
  ( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )
  exit 0
fi

if [ $1 == "deploy" ]; then
  $DEPLOY_CMD
elif [ $1 == "uploads-push" ]; then
  $UPLOADS_PUSH_CMD
elif [ $1 == "uploads-pull" ]; then
  $UPLOADS_PULL_CMD
else
  echo "Error: $1 is not a valid action."
  echo
  echo "Available actions:"
  echo "deploy"
  echo "uploads-push"
  echo "uploads-pull"
  exit 0
fi
