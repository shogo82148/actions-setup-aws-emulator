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

# download the package file
curl -fsSLO "$BASE/$PACKAGE_FILE"

# TODO: verify the downloaded package file

# install the package file
sudo apt-get install -y "./$PACKAGE_FILE"

echo "AWS Emulator version:" >&2
aws-emulator -v

# start the AWS Emulator in the background
echo "Starting AWS Emulator..." >&2
nohup aws-emulator > aws-emulator.log 2>&1 &

# wait for the AWS Emulator to become healthy
CA="${HOME}/.aws/emulator/9297/ca.pem"
for _ in $(seq 1 30); do
  if curl -fs --cacert "$CA" https://127.0.0.1:9297/__admin/health; then
    exit 0
  fi
  sleep 1
done

echo "AWS Emulator did not become healthy in time" >&2
cat aws-emulator.log
exit 1
