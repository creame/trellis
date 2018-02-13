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

[[ $# -lt $NUM_ARGS || $1 = -h ]] && { show_usage; exit 0; }

ACTION="$1"; shift
ENV="$1"; shift
EXTRA_PARAMS=$@

# allow use of abbreviations of environment
if [[ $ENV = p || $ENV = prod ]]; then
  ENV="production"
elif [[ $ENV = s || $ENV = stag ]]; then
  ENV="staging"
fi

# Import your SSH key password into Keychain on Mac OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  ssh-add -K
fi

HOSTS_FILE="hosts/$ENV"

if [[ ! -e $HOSTS_FILE ]]; then
  echo "Error: <$ENV> is not a valid environment ($HOSTS_FILE does not exist)."
  echo
  echo "Available environments:"
  ( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )
  exit 0
fi

if [ $ACTION == "provision" ]; then
  ansible-playbook server.yml -e env=$ENV $EXTRA_PARAMS
elif [ $ACTION == "deploy" ]; then
  ansible-playbook deploy.yml -e env=$ENV -e site=$SITE $EXTRA_PARAMS
elif [ $ACTION == "uploads-push" ]; then
  ansible-playbook uploads.yml -i hosts/$ENV -e site=$SITE -e mode=push
elif [ $ACTION == "uploads-pull" ]; then
  ansible-playbook uploads.yml -i hosts/$ENV -e site=$SITE -e mode=pull
elif [ $ACTION == "ssh-web" ]; then
  ssh web@$(cat hosts/$ENV | sed -n 5p)
elif [ $ACTION == "ssh-admin" ]; then
  echo
  ansible-vault view group_vars/$ENV/vault.yml | grep "    password:"
  echo
  ssh admin@$(cat hosts/$ENV | sed -n 5p)
else
  echo "Error: <$ACTION> is not a valid action."
  echo
  echo "Available actions:"
  echo "provision"
  echo "deploy"
  echo "uploads-push / uploads-pull"
  echo "ssh-web / ssh-admin"
  exit 0
fi
