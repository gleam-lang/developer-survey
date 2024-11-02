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
Image=ghcr.io/gleam-lang/developer-survey:1.2.0
PublishPort=8000:8000
Volume=/mnt/data/gleam-developer-survey:/app/data:rw,z

[Install]
WantedBy=multi-user.target default.target
```
