#!/bin/sh

set -e;

PATHS_TO_LINT="$*"

BLACK_VERSION=`black --version`
ISORT_VERSION=`isort --version-number`

echo 'Running linters on path(s):' $PATHS_TO_LINT
echo '----------------------------------------------------------------------'

echo 'Running' $BLACK_VERSION;
black --config pyproject.toml $PATHS_TO_LINT;
echo '----------------------------------------------------------------------'

echo 'Running isort' $ISORT_VERSION;
isort --settings-path pyproject.toml $PATHS_TO_LINT;
echo '----------------------------------------------------------------------'

echo 'Code formatting done!';
