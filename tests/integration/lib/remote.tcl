# SSH transport procs for integration tests.
# Callers must set before sourcing:
#   ssh_host  — target hostname (e.g. nix-builder.local)
#   ssh_port  — target SSH port (e.g. 22)
#   ssh_user  — remote user (typically "builder")
# Optional:
#   ssh_proxy — ProxyJump host (e.g. builder@nix-builder.local)

set _ssh_ctl_path ""

proc ssh_ensure_mux {} {
    global ssh_host ssh_port ssh_user _ssh_ctl_path
    if {$_ssh_ctl_path ne "" && [file exists $_ssh_ctl_path]} {
        return
    }
    set _ssh_ctl_path "/tmp/smoke-ssh-mux-[pid]"
    set cmd [list ssh -o BatchMode=yes -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
        -o LogLevel=ERROR \
        -o "ControlMaster=yes" -o "ControlPath=$_ssh_ctl_path" \
        -o "ControlPersist=300" -fN]
    if {[info exists ::ssh_proxy] && $::ssh_proxy ne ""} {
        lappend cmd -o "ProxyJump=$::ssh_proxy"
    }
    lappend cmd -p $ssh_port ${ssh_user}@${ssh_host}
    exec {*}$cmd
    after 500
}

proc ssh_base_opts {} {
    global ssh_host ssh_port ssh_user _ssh_ctl_path
    ssh_ensure_mux
    set opts [list ssh -o BatchMode=yes -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        -o "ControlPath=$_ssh_ctl_path"]
    lappend opts -p $ssh_port ${ssh_user}@${ssh_host}
    return $opts
}

proc remote {args} {
    set cmd [ssh_base_opts]
    lappend cmd {*}$args
    set rc [catch {exec {*}$cmd 2>@stderr} output]
    return [list $rc $output]
}

proc remote_sh {cmdstr} {
    set cmd [ssh_base_opts]
    lappend cmd $cmdstr
    set rc [catch {exec {*}$cmd 2>@stderr} output]
    return [list $rc $output]
}
