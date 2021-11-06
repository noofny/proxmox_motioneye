# MotionEye on ProxMox

<p align="center">
    <img height="200" alt="MotionEye Logo" src="img/logo_motioneye.png">
    <img height="200" alt="ProxMox Logo" src="img/logo_proxmox.png">
</p>

Create a [ProxMox](https://www.proxmox.com/en/) LXC container running Debian and install [MotionEye.](https://github.com/ccrisan/motioneye/)

Tested on ProxMox v7 and MotionEye v0.42

## Usage

SSH to your ProxMox server as a privileged user and run...

```shell
bash -c "$(wget --no-cache -qLO - https://raw.githubusercontent.com/noofny/proxmox_motioneye/master/setup.sh)"
```

## Inspiration

- [proxmox motioneye container](https://github.com/JedimasterRDW/proxmox_motioneye_container)
