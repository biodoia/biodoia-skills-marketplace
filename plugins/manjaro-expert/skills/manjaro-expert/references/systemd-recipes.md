# systemd Recipes — Unit Templates, Timers, and Management

## Create a System Service

Place unit files in `/etc/systemd/system/` for system services.

### Basic Daemon Service

```ini
# /etc/systemd/system/my-daemon.service
[Unit]
Description=My Custom Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/my-daemon --config /etc/my-daemon.conf
Restart=on-failure
RestartSec=5
User=myuser
Group=mygroup

# Hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/my-daemon

[Install]
WantedBy=multi-user.target
```

### One-Shot Service (run once, then exit)

```ini
# /etc/systemd/system/my-task.service
[Unit]
Description=Run a one-time task
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/my-script.sh
RemainAfterExit=no
User=root

[Install]
WantedBy=multi-user.target
```

### Forking Service (traditional daemons that daemonize)

```ini
# /etc/systemd/system/legacy-daemon.service
[Unit]
Description=Legacy Forking Daemon
After=network.target

[Service]
Type=forking
PIDFile=/var/run/legacy-daemon.pid
ExecStart=/usr/sbin/legacy-daemon -d
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Service Types Explained

| Type | Behavior |
|------|----------|
| `simple` | Default. Process started by ExecStart IS the main process. |
| `exec` | Like simple, but systemd waits for the binary to execute (not just fork). |
| `forking` | Process forks and parent exits. Use PIDFile to track. |
| `oneshot` | Process runs to completion. Good for scripts. |
| `notify` | Process sends sd_notify() when ready. Best for aware daemons. |
| `dbus` | Ready when the specified BusName appears on D-Bus. |
| `idle` | Like simple, but delayed until all jobs are done. |

---

## Create a User Service

Place unit files in `~/.config/systemd/user/`. No `sudo` needed.

### User Service Template

```ini
# ~/.config/systemd/user/my-app.service
[Unit]
Description=My User Application
After=default.target

[Service]
Type=simple
ExecStart=/home/user/bin/my-app
Restart=on-failure
RestartSec=5
Environment=HOME=/home/user
Environment=MY_VAR=value

[Install]
WantedBy=default.target
```

### Enable and Manage

```bash
systemctl --user daemon-reload               # reload after creating/editing
systemctl --user enable my-app.service       # start on login
systemctl --user enable --now my-app.service # enable + start immediately
systemctl --user start my-app.service        # start now
systemctl --user stop my-app.service         # stop
systemctl --user status my-app.service       # check status
systemctl --user restart my-app.service      # restart
journalctl --user -u my-app.service -f       # follow logs
```

### Linger (keep user services running after logout)

By default, user services stop when you log out. Enable linger to keep them running:

```bash
sudo loginctl enable-linger <username>       # enable
sudo loginctl disable-linger <username>      # disable
loginctl show-user <username> | grep Linger  # check status
```

---

## Timer Units (Replacing Cron)

systemd timers are the modern replacement for cron. Each timer needs a matching .service unit.

### Periodic Timer (like cron schedule)

```ini
# ~/.config/systemd/user/backup.timer
[Unit]
Description=Run backup every 6 hours

[Timer]
OnCalendar=*-*-* 00/6:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

```ini
# ~/.config/systemd/user/backup.service
[Unit]
Description=Backup task

[Service]
Type=oneshot
ExecStart=/home/user/scripts/backup.sh
```

### OnCalendar Syntax

```
OnCalendar=*-*-* 00:00:00           # daily at midnight
OnCalendar=Mon *-*-* 09:00:00       # every Monday at 9am
OnCalendar=*-*-01 00:00:00          # first day of every month
OnCalendar=*-*-* *:00/15:00         # every 15 minutes
OnCalendar=hourly                    # shorthand for *-*-* *:00:00
OnCalendar=daily                     # shorthand for *-*-* 00:00:00
OnCalendar=weekly                    # shorthand for Mon *-*-* 00:00:00
OnCalendar=monthly                   # shorthand for *-*-01 00:00:00
```

Test expressions:

```bash
systemd-analyze calendar "Mon *-*-* 09:00:00"      # validate + show next trigger
systemd-analyze calendar --iterations=5 "hourly"    # show next 5 triggers
```

### Monotonic Timer (relative to boot/activation)

```ini
# /etc/systemd/system/cleanup.timer
[Unit]
Description=Run cleanup 15 minutes after boot, then every hour

[Timer]
OnBootSec=15min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
```

### Timer Fields Reference

| Field | Description |
|-------|-------------|
| `OnCalendar=` | Real-time (wallclock) schedule |
| `OnBootSec=` | Time after system boot |
| `OnStartupSec=` | Time after systemd started |
| `OnUnitActiveSec=` | Time after the service last activated |
| `OnUnitInactiveSec=` | Time after the service last deactivated |
| `Persistent=true` | Catch up missed runs (like anacron) |
| `RandomizedDelaySec=` | Random delay to prevent thundering herd |
| `AccuracySec=` | Timer accuracy (default 1min, set to 1us for precision) |
| `Unit=` | Override which service to trigger (default: same name) |

### Managing Timers

```bash
systemctl list-timers --all                  # list all timers with next/last trigger
systemctl --user list-timers                 # user timers
systemctl enable --now backup.timer          # enable + start the timer
systemctl start backup.service               # trigger manually (run the service now)
journalctl -u backup.service                 # check service logs
```

---

## Journal Management

### Viewing Logs

```bash
# By unit
journalctl -u sshd                          # all logs for sshd
journalctl -u sshd -f                       # follow (live tail)
journalctl -u sshd -n 50                    # last 50 lines
journalctl -u sshd --since "2024-01-01"     # since date
journalctl -u sshd --since "1 hour ago"     # relative time
journalctl -u sshd --since "2024-01-01 10:00" --until "2024-01-01 12:00"

# By priority
journalctl -p emerg                          # 0: system is unusable
journalctl -p alert                          # 1: action must be taken
journalctl -p crit                           # 2: critical conditions
journalctl -p err                            # 3: errors
journalctl -p warning                        # 4: warnings
journalctl -p notice                         # 5: normal but significant
journalctl -p info                           # 6: informational
journalctl -p debug                          # 7: debug

# By boot
journalctl -b                                # current boot
journalctl -b -1                             # previous boot
journalctl --list-boots                      # list all boots
journalctl -b <boot-id>                      # specific boot

# Kernel messages
journalctl -k                                # kernel messages (like dmesg)
journalctl -k -b -1                          # kernel messages from last boot

# By PID / executable
journalctl _PID=1234                         # specific process
journalctl _EXE=/usr/bin/nginx               # specific executable
journalctl _UID=1000                         # specific user

# Output formats
journalctl -o json-pretty                    # JSON output
journalctl -o short-iso                      # ISO timestamps
journalctl -o verbose                        # all fields
journalctl -o cat                            # message only, no metadata

# User journal
journalctl --user -u my-app                  # user service logs
```

### Journal Disk Management

```bash
journalctl --disk-usage                      # current journal size
sudo journalctl --vacuum-size=500M           # shrink to 500MB
sudo journalctl --vacuum-time=2weeks         # remove entries older than 2 weeks
sudo journalctl --vacuum-files=5             # keep only 5 journal files
sudo journalctl --rotate                     # force log rotation now
```

Persistent configuration in `/etc/systemd/journald.conf`:

```ini
[Journal]
SystemMaxUse=500M                            # max disk usage
SystemMaxFileSize=50M                        # max per-file size
MaxRetentionSec=1month                       # auto-delete after 1 month
Compress=yes                                 # compress stored journals
Storage=persistent                           # store in /var/log/journal/ (survives reboot)
# Storage=volatile                           # store in /run/log/journal/ (RAM only)
```

After editing: `sudo systemctl restart systemd-journald`

---

## Boot Analysis

```bash
systemd-analyze                              # total boot time (firmware → loader → kernel → userspace)
systemd-analyze blame                        # time per unit (slowest first)
systemd-analyze critical-chain               # critical path (what blocked boot)
systemd-analyze critical-chain sshd.service  # what delayed a specific service
systemd-analyze plot > boot.svg              # visual boot chart (open in browser)
systemd-analyze dot | dot -Tsvg > deps.svg   # dependency graph
systemd-analyze verify my-unit.service       # validate unit file syntax
systemd-analyze security my.service          # security audit of a service
systemd-analyze calendar "daily"             # test OnCalendar expressions
```

---

## Useful Unit File Templates

### Web Application (Node.js / Go / Python)

```ini
# /etc/systemd/system/webapp.service
[Unit]
Description=My Web Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=webapp
Group=webapp
WorkingDirectory=/opt/webapp
ExecStart=/opt/webapp/server --port 8080
Restart=always
RestartSec=5

# Environment
Environment=NODE_ENV=production
EnvironmentFile=-/opt/webapp/.env

# Limits
LimitNOFILE=65536

# Hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/webapp/data /var/log/webapp
PrivateTmp=true

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=webapp

[Install]
WantedBy=multi-user.target
```

### Docker Container as Service

```ini
# /etc/systemd/system/my-container.service
[Unit]
Description=My Docker Container
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/docker stop my-container
ExecStartPre=-/usr/bin/docker rm my-container
ExecStart=/usr/bin/docker run --name my-container \
    -p 8080:8080 \
    -v /opt/data:/data \
    --rm \
    my-image:latest
ExecStop=/usr/bin/docker stop my-container

[Install]
WantedBy=multi-user.target
```

### Mount Unit

```ini
# /etc/systemd/system/mnt-data.mount
# Note: unit name must match mount path (mnt-data = /mnt/data)
[Unit]
Description=Mount Data Drive

[Mount]
What=/dev/disk/by-uuid/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Where=/mnt/data
Type=ext4
Options=defaults,noatime

[Install]
WantedBy=multi-user.target
```

### Path Unit (Watch for file changes)

```ini
# /etc/systemd/system/deploy-watch.path
[Unit]
Description=Watch for deployment trigger

[Path]
PathChanged=/opt/deploy/trigger
MakeDirectory=yes

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/deploy-watch.service
[Unit]
Description=Run deployment

[Service]
Type=oneshot
ExecStart=/opt/deploy/run-deploy.sh
```

### Socket Activation

```ini
# /etc/systemd/system/my-app.socket
[Unit]
Description=My App Socket

[Socket]
ListenStream=8080
Accept=no

[Install]
WantedBy=sockets.target
```

```ini
# /etc/systemd/system/my-app.service
[Unit]
Description=My App (socket-activated)
Requires=my-app.socket

[Service]
Type=simple
ExecStart=/opt/my-app/server
```

The service starts only when a connection arrives on port 8080. Zero resource usage when idle.

---

## Service Hardening Options

Apply these in the `[Service]` section to restrict what a service can do:

```ini
# Filesystem
ProtectSystem=strict                # mount / as read-only (use ReadWritePaths= for exceptions)
ProtectHome=true                    # hide /home, /root, /run/user
ReadWritePaths=/var/lib/myapp       # whitelist writable paths
PrivateTmp=true                     # isolated /tmp
ReadOnlyPaths=/etc                  # force read-only

# Privileges
NoNewPrivileges=true                # prevent privilege escalation
CapabilityBoundingSet=CAP_NET_BIND_SERVICE  # limit capabilities
AmbientCapabilities=CAP_NET_BIND_SERVICE    # grant specific capabilities

# Network
PrivateNetwork=true                 # no network access (isolated)
RestrictAddressFamilies=AF_INET AF_INET6  # only IPv4/IPv6

# System calls
SystemCallFilter=@system-service    # allow only common syscalls
SystemCallArchitectures=native      # prevent 32-bit syscalls

# Other
ProtectKernelTunables=true          # no /proc/sys, /sys writes
ProtectKernelModules=true           # no module loading
ProtectControlGroups=true           # no cgroup modifications
RestrictRealtime=true               # no realtime scheduling
MemoryDenyWriteExecute=true         # no W^X violations (JIT blocked)
LockPersonality=true                # lock execution domain
```

Audit a service's security:

```bash
systemd-analyze security my.service          # score from 0 (best) to 10 (worst)
```

---

## Dependency and Ordering

```ini
[Unit]
# Ordering (when to start relative to others)
After=network-online.target          # start after network is up
Before=httpd.service                 # start before httpd

# Dependencies (what must also be running)
Requires=postgresql.service          # hard dependency (fail if postgres fails)
Wants=redis.service                  # soft dependency (don't fail if redis fails)
BindsTo=docker.service               # stop if docker stops
PartOf=app.target                    # stop/restart when target does

# Conflict
Conflicts=other.service              # cannot run at the same time
```

---

## Targets (Grouping Units)

Create a custom target to group related services:

```ini
# /etc/systemd/system/my-stack.target
[Unit]
Description=My Application Stack
Requires=webapp.service worker.service
After=webapp.service worker.service

[Install]
WantedBy=multi-user.target
```

Then: `sudo systemctl enable --now my-stack.target`

Built-in targets:
- `multi-user.target` -- normal multi-user mode (like runlevel 3)
- `graphical.target` -- GUI mode (like runlevel 5)
- `rescue.target` -- single-user rescue mode
- `emergency.target` -- minimal emergency shell
- `network-online.target` -- network is fully up

---

## Drop-In Overrides

Override parts of a unit without editing the original file:

```bash
sudo systemctl edit my.service               # creates drop-in override
# Or manually: /etc/systemd/system/my.service.d/override.conf
```

```ini
# /etc/systemd/system/my.service.d/override.conf
[Service]
Environment=MY_VAR=new-value
RestartSec=10
```

This merges with the original. To replace a field entirely, clear it first:

```ini
[Service]
ExecStart=                                   # clear original ExecStart
ExecStart=/new/path/to/binary                # set new value
```
