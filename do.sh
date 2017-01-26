#!/bin/bash
shopt -s nullglob

NUM_ARGS=2

ENVIRONMENTS=( hosts/* )
ENVIRONMENTS=( "${ENVIRONMENTS[@]##*/}" )

SITE="$(dirname "$(dirname "$(readlink -f "$0")")")"
SITE=${SITE##*/}

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

[[ $# -ne $NUM_ARGS || $1 = -h ]] && { show_usage; exit 0; }

# allow use of first letter of environment
ENV=$2
if [ $ENV == "p" ]; then
  ENV="production"
elif [ $ENV == "s" ]; then
  ENV="staging"
fi

HOSTS_FILE="hosts/$ENV"

if [[ ! -e $HOSTS_FILE ]]; then
  echo "Error: <$ENV> is not a valid environment ($HOSTS_FILE does not exist)."
  echo
  echo "Available environments:"
  ( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )
  exit 0
fi

if [ $1 == "provision" ]; then
  ansible-playbook server.yml -e env=$ENV
elif [ $1 == "deploy" ]; then
  ansible-playbook deploy.yml -e env=$ENV -e site=$SITE
elif [ $1 == "uploads-push" ]; then
  ansible-playbook uploads.yml -i hosts/$ENV -e site=$SITE -e mode=push
elif [ $1 == "uploads-pull" ]; then
  ansible-playbook uploads.yml -i hosts/$ENV -e site=$SITE -e mode=pull
elif [ $1 == "ssh-web" ]; then
  ssh web@$(cat hosts/$ENV | sed -n 5p)
elif [ $1 == "ssh-admin" ]; then
  echo
  ansible-vault view group_vars/$ENV/vault.yml | grep "    password:"
  echo
  ssh admin@$(cat hosts/$ENV | sed -n 5p)
else
  echo "Error: <$1> is not a valid action."
  echo
  echo "Available actions:"
  echo "provision"
  echo "deploy"
  echo "uploads-push / uploads-pull"
  echo "ssh-web / ssh-admin"
  exit 0
fi
