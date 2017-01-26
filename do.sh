#!/bin/bash
shopt -s nullglob

NUM_ARGS=2

ENVIRONMENTS=( hosts/* )
ENVIRONMENTS=( "${ENVIRONMENTS[@]##*/}" )

SITE="$(dirname "$(dirname "$(readlink -f "$0")")")"
SITE=${SITE##*/}

PROVISION_CMD="ansible-playbook server.yml -e env=$2"
DEPLOY_CMD="ansible-playbook deploy.yml -e env=$2 -e site=$SITE"
UPLOADS_PUSH_CMD="ansible-playbook uploads.yml -i hosts/$2 -e site=$SITE -e mode=push"
UPLOADS_PULL_CMD="ansible-playbook uploads.yml -i hosts/$2 -e site=$SITE -e mode=pull"


show_usage() {
  echo "Usage: ./do.sh <action> <environment>

<action> is the action to perform (deploy, uploads-push...)
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
  echo "Error: <$2> is not a valid environment ($HOSTS_FILE does not exist)."
  echo
  echo "Available environments:"
  ( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )
  exit 0
fi

if [ $1 == "provision" ]; then
  $PROVISION_CMD
elif [ $1 == "deploy" ]; then
  $DEPLOY_CMD
elif [ $1 == "uploads-push" ]; then
  $UPLOADS_PUSH_CMD
elif [ $1 == "uploads-pull" ]; then
  $UPLOADS_PULL_CMD
elif [ $1 == "ssh-web" ]; then
  ssh web@$(cat hosts/$2 | sed -n 5p)
elif [ $1 == "ssh-admin" ]; then
  echo
  ansible-vault view group_vars/$2/vault.yml | grep "    password:"
  echo
  ssh admin@$(cat hosts/$2 | sed -n 5p)
else
  echo "Error: $1 is not a valid action."
  echo
  echo "Available actions:"
  echo "provision"
  echo "deploy"
  echo "uploads-push / uploads-pull"
  echo "ssh-web / ssh-admin"
  exit 0
fi
