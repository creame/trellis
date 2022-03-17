#!/bin/bash
shopt -s nullglob

# shell colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
RESET=`tput sgr0`

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

[[ $# -lt $NUM_ARGS || $1 = -h ]] && { show_usage; exit 127; }

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
  echo
  echo "${RED}Error: <$ENV> is not a valid environment ($HOSTS_FILE does not exist).${RESET}"
  echo
  echo "Available environments:"
  ( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )
  echo
  exit 1
else
  echo
  echo "${BLUE}Doing $ACTION for '$SITE' on <$ENV>...${RESET}"
  echo
fi

if [ $ACTION == "provision" ]; then
  ansible-playbook server.yml -e env=$ENV $EXTRA_PARAMS
elif [ $ACTION == "deploy" ]; then
  ansible-playbook deploy.yml -e env=$ENV -e site=$SITE $EXTRA_PARAMS
elif [ $ACTION == "uploads-push" ]; then
  ansible-playbook uploads.yml  -e env=$ENV -e site=$SITE -e mode=push
elif [ $ACTION == "uploads-pull" ]; then
  ansible-playbook uploads.yml  -e env=$ENV -e site=$SITE -e mode=pull
elif [ $ACTION == "db-push" ]; then
  ansible-playbook database.yml -e env=$ENV -e site=$SITE -e mode=push
elif [ $ACTION == "db-pull" ]; then
  ansible-playbook database.yml -e env=$ENV -e site=$SITE -e mode=pull
elif [ $ACTION == "loco-pull" ]; then
  ansible-playbook uploads.yml  -e env=$ENV -e site=$SITE -e mode=loco
elif [ $ACTION == "pull" ]; then
  ansible-playbook database.yml -e env=$ENV -e site=$SITE -e mode=pull
  ansible-playbook uploads.yml  -e env=$ENV -e site=$SITE -e mode=pull
  ansible-playbook uploads.yml  -e env=$ENV -e site=$SITE -e mode=loco
elif [ $ACTION == "push" ]; then
  ansible-playbook database.yml -e env=$ENV -e site=$SITE -e mode=push
  ansible-playbook uploads.yml  -e env=$ENV -e site=$SITE -e mode=push
elif [ $ACTION == "ssh-web" ]; then
  ssh web@$(cat hosts/$ENV | sed -n 5p)
elif [ $ACTION == "ssh-admin" ]; then
  echo $GREEN
  ansible-vault view group_vars/$ENV/vault.yml | grep "    password:"
  echo $RESET
  ssh admin@$(cat hosts/$ENV | sed -n 5p)
else
  echo "${RED}Error: <$ACTION> is not a valid action.${RESET}"
  echo
  echo "Available actions:"
  echo "provision"
  echo "deploy"
  echo "uploads-push / uploads-pull"
  echo "db-push / db-pull"
  echo "loco-pull"
  echo "ssh-web / ssh-admin"
  echo
  exit 1
fi
