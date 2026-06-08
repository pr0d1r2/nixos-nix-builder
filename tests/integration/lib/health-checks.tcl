# Shared health checks for NixOS builder validation.
#
# Requires: remote.tcl and checks.tcl sourced first.
# Requires: ssh_host, ssh_port, ssh_user set by caller.
#
# Usage:
#   run_health_checks label expected_hostname ?skip_tags?
#
# skip_tags: list of sections to skip
#   "hardware" — KVM device, microcode, real storage tiers
#   "network"  — interface UP, default route (not meaningful in QEMU SLIRP)
#   "mdns"     — avahi publish/resolve (QEMU guest mDNS differs)
#   "boot"     — GRUB config (not accessible from live ISO rootfs)
#   "qemu"     — 9p host store mount (only present in QEMU guests)
#   "gc"       — nix-store-gc timer (skip on live until builder reburned
#                with an ISO containing the module)

proc run_health_checks {label expected_hostname {skip_tags {}}} {

    puts "\n${label}: --- health checks ---"

    # -- Hostname ----------------------------------------------------------

    check_contains "hostname" $expected_hostname hostname

    # -- systemd healthy ---------------------------------------------------

    check_sh_contains "systemd is running" "running" \
        "systemctl is-system-running --wait || systemctl is-system-running"

    # -- Core services -----------------------------------------------------

    puts "\n${label}: --- core services ---"

    check_contains "nix-serve active" "active" \
        systemctl is-active nix-serve

    check_contains "avahi-daemon active" "active" \
        systemctl is-active avahi-daemon

    check_contains "sshd active" "active" \
        systemctl is-active sshd

    check_contains "nix-daemon active" "active" \
        systemctl is-active nix-daemon

    check_contains "timesyncd active" "active" \
        systemctl is-active systemd-timesyncd

    check_contains "firewall active" "active" \
        systemctl is-active firewall

    check_contains "NetworkManager active" "active" \
        systemctl is-active NetworkManager

    # -- nix-serve health --------------------------------------------------

    puts "\n${label}: --- nix-serve ---"

    check_sh_contains "nix-serve responds on :5000" "StoreDir" \
        "curl -sf http://localhost:5000/nix-cache-info"

    check_sh_contains "nix-serve listens on :5000" ":5000" \
        "ss -tlnp | grep 5000"

    # -- SSH hardening -----------------------------------------------------

    puts "\n${label}: --- SSH hardening ---"

    check_sh_contains "sshd max auth tries = 3" "MaxAuthTries 3" \
        "cat /etc/ssh/sshd_config"

    check_sh_contains "sshd no password auth" "PasswordAuthentication no" \
        "cat /etc/ssh/sshd_config"

    check_sh_contains "sshd local-only TCP forwarding" "AllowTcpForwarding local" \
        "cat /etc/ssh/sshd_config"

    puts -nonewline "  check: SSH host key is ed25519 only ... "
    lassign [remote_sh "ls /etc/ssh/ssh_host_*_key.pub 2>/dev/null"] rc output
    set output [string trim $output]
    if {$rc != 0 || $output eq ""} {
        puts "FAIL (no host keys found)"
        bail "no SSH host key public files found"
    }
    if {[string first "ed25519" $output] == -1} {
        puts "FAIL (no ed25519 key)"
        bail "expected ed25519 host key, found: $output"
    }
    foreach bad_type {rsa ecdsa dsa} {
        if {[string first $bad_type $output] != -1} {
            puts "FAIL (unexpected $bad_type key)"
            bail "found $bad_type host key alongside ed25519: $output"
        }
    }
    puts "ok"

    # -- Users -------------------------------------------------------------

    puts "\n${label}: --- users ---"

    puts -nonewline "  check: builder uid=1000 ... "
    lassign [remote id -u builder] rc output
    if {$rc != 0 || [string trim $output] ne "1000"} {
        puts "FAIL"
        bail "builder uid: expected 1000, got $output"
    }
    puts "ok"

    puts -nonewline "  check: builder gid=1000 ... "
    lassign [remote id -g builder] rc output
    if {$rc != 0 || [string trim $output] ne "1000"} {
        puts "FAIL"
        bail "builder gid: expected 1000, got $output"
    }
    puts "ok"

    # -- Machine ID --------------------------------------------------------

    check_contains "machine-id stable" "5b23f4305970f426c3d1c00d0c2aa0e3" \
        cat /etc/machine-id

    # -- Kernel and boot ---------------------------------------------------

    puts "\n${label}: --- kernel and boot ---"

    puts -nonewline "  check: kernel version ... "
    lassign [remote uname -a] rc output
    if {$rc != 0} {
        puts "FAIL"
        bail "uname -a failed: $output"
    }
    puts "ok ($output)"

    puts -nonewline "  check: no critical dmesg errors ... "
    lassign [remote_sh "journalctl -k -p crit 2>/dev/null | grep -v '^-- ' | head -5 || true"] rc output
    set output [string trim $output]
    if {$output ne ""} {
        puts "WARN"
        foreach line [split $output "\n"] { puts "    $line" }
    } else {
        puts "ok"
    }

    if {"boot" ni $skip_tags} {
        puts -nonewline "  check: boot timeout = 1s ... "
        lassign [remote_sh "grep 'set timeout' /boot/grub/grub.cfg 2>/dev/null"] rc output
        set output [string trim $output]
        if {[string first "1" $output] != -1} {
            puts "ok ($output)"
        } else {
            puts "FAIL (expected timeout=1: $output)"
            bail "GRUB boot timeout is not 1s: $output"
        }
    }

    # -- Filesystem --------------------------------------------------------

    puts "\n${label}: --- filesystem ---"

    puts -nonewline "  check: root filesystem type ... "
    lassign [remote_sh "findmnt -n -o FSTYPE /"] rc rootfs
    set rootfs [string trim $rootfs]
    puts "ok ($rootfs)"

    puts -nonewline "  check: nix store mount ... "
    lassign [remote_sh "findmnt -n -o FSTYPE /nix/store 2>/dev/null || echo unknown"] rc nixfs
    puts "ok ([string trim $nixfs])"

    # -- Storage -----------------------------------------------------------

    puts "\n${label}: --- storage ---"

    puts -nonewline "  check: /mnt/storage exists ... "
    lassign [remote_sh "test -d /mnt/storage && ls /mnt/storage"] rc output
    if {$rc != 0} {
        puts "FAIL"
        bail "/mnt/storage does not exist or is not a directory"
    }
    puts "ok ($output)"

    puts -nonewline "  check: nix store overlay active ... "
    lassign [remote_sh "findmnt -n -o FSTYPE /nix/store | head -1"] rc overlay_type
    set overlay_type [string trim $overlay_type]
    if {$overlay_type eq "overlay"} {
        puts "ok (overlay)"
    } else {
        puts "FAIL (expected overlay, got $overlay_type)"
        bail "nix store overlay not active"
    }

    if {"qemu" ni $skip_tags} {
        puts -nonewline "  check: 9p host store mounted ... "
        lassign [remote_sh "mountpoint -q /mnt/nix-host-store && echo mounted || echo missing"] rc output
        set output [string trim $output]
        if {$output eq "mounted"} {
            puts "ok"
        } else {
            puts "FAIL"
            bail "/mnt/nix-host-store not mounted — 9p passthrough inactive"
        }

        puts -nonewline "  check: overlay includes 9p lower layer ... "
        lassign [remote_sh "findmnt -n -o OPTIONS /nix/store 2>/dev/null"] rc opts
        set opts [string trim $opts]
        if {[string first "nix-host-store" $opts] != -1} {
            puts "ok"
        } else {
            puts "FAIL"
            bail "overlay lowerdir missing nix-host-store: $opts"
        }
    }

    if {"hardware" ni $skip_tags} {
        puts -nonewline "  check: nix store on disk (not tmpfs) ... "
        lassign [remote_sh "df -T /nix/store 2>/dev/null | tail -1"] rc df_line
        set df_line [string trim $df_line]
        if {[string first "tmpfs" $df_line] != -1} {
            puts "FAIL (nix store on tmpfs)"
            bail "nix store is on tmpfs — overlay not redirected to disk"
        }
        puts "ok ($df_line)"

        puts -nonewline "  check: /mnt/storage is bind mount from storage tier ... "
        lassign [remote_sh "findmnt -n -o SOURCE /mnt/storage 2>/dev/null"] rc mount_src
        set mount_src [string trim $mount_src]
        if {$mount_src eq ""} {
            puts "FAIL (not a mount point)"
            bail "/mnt/storage is not a mount point"
        } else {
            puts "ok ($mount_src)"
        }
    }

    puts -nonewline "  check: nix build-dir on storage ... "
    lassign [remote_sh "nix show-config 2>/dev/null | grep build-dir | head -1"] rc build_dir
    set build_dir [string trim $build_dir]
    if {[string first "/mnt/storage" $build_dir] != -1} {
        puts "ok ($build_dir)"
    } else {
        puts "FAIL ($build_dir)"
        bail "nix build-dir not on /mnt/storage"
    }

    puts "  df -h:"
    lassign [remote_sh "df -h -x devtmpfs -x tmpfs 2>/dev/null || df -h"] _ df_out
    foreach line [split $df_out "\n"] {
        if {$line ne ""} { puts "    $line" }
    }

    # -- Network -----------------------------------------------------------

    if {"network" ni $skip_tags} {
        puts "\n${label}: --- network ---"

        puts -nonewline "  check: non-loopback interface UP ... "
        lassign [remote_sh "ip -o link show up | grep -v '\\blo\\b' || true"] rc output
        if {[string trim $output] eq ""} {
            puts "FAIL"
            bail "no non-loopback interfaces are UP"
        }
        puts "ok"

        puts -nonewline "  check: default route exists ... "
        lassign [remote_sh "ip route show default"] rc def_route
        set def_route [string trim $def_route]
        if {$def_route eq ""} {
            puts "FAIL"
            bail "no default route"
        }
        puts "ok ($def_route)"
    }

    # -- mDNS (dual hostname) ---------------------------------------------

    if {"mdns" ni $skip_tags} {
        puts "\n${label}: --- mDNS ---"

        puts -nonewline "  check: avahi publishes nix-builder ... "
        lassign [remote_sh "avahi-browse -a -t -p 2>/dev/null | head -20 || true"] rc avahi_out
        if {[string first "nix-builder" $avahi_out] != -1} {
            puts "ok"
        } else {
            puts "info (could not verify via avahi-browse)"
        }

        check "nix-serve.local resolves via mDNS" \
            avahi-resolve-host-name nix-serve.local
    }

    # -- Nix config --------------------------------------------------------

    puts "\n${label}: --- nix config ---"

    check_sh_contains "trusted-users includes root builder" "root builder" \
        "nix show-config trusted-users 2>/dev/null"

    check_sh_contains "nix sandbox enabled" "true" \
        "nix show-config sandbox 2>/dev/null"

    puts -nonewline "  check: nix max-jobs = auto (resolved) ... "
    lassign [remote_sh "nix show-config max-jobs 2>/dev/null"] rc output
    set output [string trim $output]
    if {$rc != 0} {
        puts "FAIL"
        bail "nix show-config max-jobs failed: $output"
    }
    if {[regexp {(\d+)} $output _ n] && $n > 0} {
        puts "ok ($output)"
    } else {
        puts "FAIL"
        bail "max-jobs expected positive integer, got: $output"
    }

    check_sh_contains "nix cores = 0" "0" \
        "nix show-config cores 2>/dev/null"

    check_sh_contains "flakes enabled" "flakes" \
        "nix show-config experimental-features 2>/dev/null"

    check_sh_contains "nix-command enabled" "nix-command" \
        "nix show-config experimental-features 2>/dev/null"

    check_sh_contains "cachix substituter configured" "cachix.org" \
        "nix show-config substituters 2>/dev/null"

    # -- Builder capabilities ----------------------------------------------

    puts "\n${label}: --- builder capabilities ---"

    check_sh_contains "builder in kvm group" "kvm" \
        "id -Gn builder"

    check_sh_contains "builder in wheel group" "wheel" \
        "id -Gn builder"

    check_sh_contains "builder in networkmanager group" "networkmanager" \
        "id -Gn builder"

    # -- Declarative users -------------------------------------------------

    # -- Service ordering --------------------------------------------------

    puts "\n${label}: --- service ordering ---"

    check_sh_contains "nix-serve starts after overlay" "nix-store-overlay.service" \
        "systemctl show nix-serve -p After --value"

    check_sh_contains "overlay preStop wired" "ExecStop" \
        "systemctl cat nix-store-overlay 2>/dev/null"

    # -- Periodic maintenance ----------------------------------------------

    if {"gc" ni $skip_tags} {
        puts "\n${label}: --- periodic maintenance ---"

        check_contains "nix-store-gc timer active" "active" \
            systemctl is-active nix-store-gc.timer

        check_sh_contains "nix-store-gc timer fires 03:00 UTC" "03:00:00" \
            "systemctl show -p TimersCalendar nix-store-gc.timer"

        check_sh_contains "nix-store-gc timer persistent" "Persistent=yes" \
            "systemctl show -p Persistent nix-store-gc.timer"

        check_sh_contains "nix-store-gc service loaded" "loaded" \
            "systemctl show -p LoadState --value nix-store-gc.service"

        check_sh_contains "nix-store-gc no-op under threshold" "no action needed" \
            {NIX_GC_THRESHOLD=100 $(systemctl show -p ExecStart --value nix-store-gc.service | grep -oP 'path=\K[^ ;]+')}
    }

    # -- Headless ----------------------------------------------------------

    puts "\n${label}: --- headless ---"

    puts -nonewline "  check: no display-manager running ... "
    lassign [remote_sh "systemctl is-active display-manager 2>/dev/null || true"] rc output
    set output [string trim $output]
    if {$output eq "active"} {
        puts "FAIL"
        bail "display-manager is active -- system is not headless"
    }
    puts "ok ($output)"

    # -- Hardware ----------------------------------------------------------

    if {"hardware" ni $skip_tags} {
        puts "\n${label}: --- hardware ---"

        check "KVM device available" test -c /dev/kvm

        check_sh_contains "AMD microcode loaded" "microcode" \
            "journalctl -k 2>/dev/null | grep -i microcode | head -3"
    }

    check_sh_contains "tmpfs mounted on /tmp" "tmpfs" \
        "findmnt -n -o FSTYPE /tmp 2>/dev/null"

    check_sh_contains "tmpfs /tmp sized 16G" "size=16777216k" \
        "findmnt -n -o OPTIONS /tmp 2>/dev/null"

    # -- Power management --------------------------------------------------

    puts "\n${label}: --- power management ---"

    check_sh_contains "IdleAction=ignore" "ignore" \
        "grep IdleAction /etc/systemd/logind.conf 2>/dev/null || grep -r IdleAction /etc/systemd/logind.conf.d/ 2>/dev/null"

    puts -nonewline "  check: sleep target disabled ... "
    lassign [remote_sh "systemctl is-enabled sleep.target 2>/dev/null || echo disabled"] rc output
    set output [string trim $output]
    if {$output eq "enabled"} {
        puts "FAIL"
        bail "sleep.target is enabled -- should be disabled/masked"
    }
    puts "ok ($output)"

    # -- Firewall rules ----------------------------------------------------

    puts "\n${label}: --- firewall rules ---"

    check_sh_contains "port 22 listening" ":22" \
        "ss -tlnp 2>/dev/null | grep ':22 '"

    check_sh_contains "port 5000 listening" ":5000" \
        "ss -tlnp 2>/dev/null | grep ':5000 '"

    check_sh_contains "mDNS port 5353 open" ":5353" \
        "ss -ulnp 2>/dev/null | grep ':5353 '"

    # -- Journal -----------------------------------------------------------

    puts "\n${label}: --- journal ---"

    check "no FAILED markers in journal" \
        bash -c {"! journalctl -b --no-pager | grep -qF '[ FAILED ]'"}

    puts "\n${label}: OK - all health checks passed"
}
