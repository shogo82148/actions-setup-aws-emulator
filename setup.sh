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
if [ "${AWS_EMULATOR_VERSION}" != "latest" ]; then
  BASE=https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS
  PACKAGE_FILE=aws-emulator_${AWS_EMULATOR_VERSION}-1_${ARCH}.deb
fi

cd "$RUNNER_TEMP"

# download the package file
curl -fsSLO "$BASE/$PACKAGE_FILE"
curl -fsSLO "$BASE/$PACKAGE_FILE.sig"

# verify the downloaded package file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GNUPGHOME="$(mktemp -d)"
trap 'rm -rf "$GNUPGHOME"' EXIT
export GNUPGHOME
gpg --batch --quiet --import "$SCRIPT_DIR/aws-emulator-key.asc"
gpg --batch --quiet --verify "$PACKAGE_FILE.sig" "$PACKAGE_FILE"

# install the package file
sudo apt-get install -y "./$PACKAGE_FILE"
rm "$PACKAGE_FILE" "$PACKAGE_FILE.sig"

echo "AWS Emulator version:" >&2
aws-emulator -v

# start the AWS Emulator in the background
echo "Starting AWS Emulator..." >&2
nohup aws-emulator > aws-emulator.log 2>&1 &

# configure environment variables for the AWS Emulator
CA="${HOME}/.aws/emulator/9297/ca.pem"
(
  echo "AWS_ENDPOINT_URL=https://127.0.0.1:9297"
  echo "AWS_SHARED_CREDENTIALS_FILE=${HOME}/.aws/emulator/9297/emulator_credentials"
  echo "AWS_CONFIG_FILE=${HOME}/.aws/emulator/9297/config"
  echo "AWS_EMULATOR_CA=$CA"
  echo "AWS_EC2_METADATA_DISABLED=true"
  echo "AWS_DISABLE_HOST_PREFIX_INJECTION=true"
  echo "AWS_REGION=us-east-1"
  echo "AWS_DEFAULT_REGION=us-east-1"
) >> "$GITHUB_ENV"

# wait for the AWS Emulator to become healthy
for _ in $(seq 1 30); do
  if curl -fs --cacert "$CA" https://127.0.0.1:9297/__admin/health >/dev/null 2>&1; then
    exit 0
  fi
  sleep 1
done

echo "AWS Emulator did not become healthy in time" >&2
cat aws-emulator.log
exit 1
