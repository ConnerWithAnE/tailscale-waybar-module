

## Setting operator

You need to set the user to be the default operator, it gets around needing sudo.

run
```sh
$ sudo systemctl edit tailscaled
```

```sh
[Service]
ExecStartPost=/usr/bin/tailscale set --operator=<username>
```
This must be done to give the user elevated permissions when running tailscale commands

```sh
$ sudo systemctl daemon-reload
$ sudo systemctl restart tailscaled
```
