# Gleam Developer Survey

Learning things about the Gleam community.

```sh
gleam run
```

# Deployment

Podman quadlet!

```ini
[Unit]
Description=Gleam Developer Survey container
After=local-fs.target

[Container]
Image=ghcr.io/gleam-lang/developer-survey:main

# Make podman-auto-update.service update it when there's a new image version
AutoUpdate=registry

# Expose the port the app is listening on
PublishPort=3000:3001

# Mount the storage
Volume=/srv/gleam-developer-survey:/app/data:rw,z

# Restart the service if the health check fails
HealthCmd=sh -c /app/healthcheck.sh
HealthInterval=30s
HealthTimeout=5s
HealthRetries=3
HealthOnFailure=restart

[Install]
WantedBy=multi-user.target default.target
```
