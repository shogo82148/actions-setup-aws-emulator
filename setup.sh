#!/usr/bin/env bash

set -euo pipefail

if [ "${RUNNER_DEBUG:-}" = "1" ] ; then
  set -x
fi

ARCH=$(uname -m)
case $ARCH in
  x86_64 | amd64)
    ARCH=amd64
    ;;
  aarch64 | arm64)
    ARCH=arm64
    ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

BASE=https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest
PACKAGE_FILE=aws-emulator_${ARCH}.deb

cd "$RUNNER_TEMP"

curl -fsSLO "$BASE/$PACKAGE_FILE"
sudo apt-get install -y "./$PACKAGE_FILE"
aws-emulator -v
nohup aws-emulator > aws-emulator.log 2>&1 &

for _ in $(seq 1 30); do
  if curl -fs https://127.0.0.1:9297/__admin/health; then
    exit 0
  fi
  sleep 1
done

echo "AWS Emulator did not become healthy in time" >&2
cat aws-emulator.log
exit 1
