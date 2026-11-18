# actions-setup-aws-emulator

Set up the [AWS Emulator](https://github.com/aws/aws-emulator) on GitHub Actions and configure the AWS CLI / SDKs to use it.

## Usage

```yaml
steps:
  - uses: shogo82148/actions-setup-aws-emulator@v0
    with:
      aws-emulator-version: "latest"
      auth: "on"
      telemetry: "off"

  - run: aws sts get-caller-identity
```

## Inputs

| Name                   | Default  | Description                                                                                                                                                                                                        |
| ---------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `aws-emulator-version` | `latest` | AWS Emulator version to install.                                                                                                                                                                                   |
| `auth`                 | `on`     | `on` or `off`. Passed as `--auth`. When `on`, requests must be signed with the emulator's generated keys. When `off`, any request is accepted and dummy credentials are exported so the AWS CLI / SDKs still work. |
| `telemetry`            | `on`     | `on` or `off`. Passed as `--telemetry`. `off` always wins over `EMULATOR_TELEMETRY` and the config file; `on` cannot override them.                                                                                |
