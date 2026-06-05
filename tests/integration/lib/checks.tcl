proc bail {msg} {
    global test_label log_path
    set prefix ""
    if {[info exists test_label]} { set prefix "${test_label}: " }
    puts stderr "\n${prefix}FAILED: $msg"
    if {[info exists log_path] && $log_path ne "" && [file exists $log_path]} {
        puts stderr "--- last 50 lines of $log_path ---"
        catch { exec tail -n 50 $log_path } tail
        puts stderr $tail
        puts stderr "--- end transcript ---"
    }
    if {[info exists ::cleanup_proc]} {
        $::cleanup_proc
    }
    exit 1
}

proc send_cmd {cmd} {
    send -- "$cmd\r"
    sleep 0.3
}

proc wait_for {desc pattern {timeout_s 60}} {
    set timeout $timeout_s
    expect {
        -re $pattern {
            puts "\[OK\]   $desc"
            return $expect_out(0,string)
        }
        timeout {
            bail "$desc -- timed out after ${timeout_s}s waiting for: $pattern"
        }
        eof {
            bail "$desc -- process exited unexpectedly"
        }
    }
}

proc check_cmd {desc cmd expected} {
    send_cmd $cmd
    wait_for $desc $expected
}

# SSH-based check procs (require remote.tcl sourced first).

proc check {desc args} {
    puts -nonewline "  check: $desc ... "
    lassign [remote {*}$args] rc output
    if {$rc != 0} {
        puts "FAIL"
        bail "$desc: $output"
    }
    puts "ok"
    return $output
}

proc check_contains {desc needle args} {
    puts -nonewline "  check: $desc ... "
    lassign [remote {*}$args] rc output
    if {$rc != 0} {
        puts "FAIL (exit code)"
        bail "$desc: command failed: $output"
    }
    if {[string first $needle $output] == -1} {
        puts "FAIL"
        bail "$desc: expected '$needle' in output: $output"
    }
    puts "ok"
    return $output
}

proc check_sh_contains {desc needle cmdstr} {
    puts -nonewline "  check: $desc ... "
    lassign [remote_sh $cmdstr] rc output
    if {$rc != 0} {
        puts "FAIL (exit code)"
        bail "$desc: command failed: $output"
    }
    if {[string first $needle $output] == -1} {
        puts "FAIL"
        bail "$desc: expected '$needle' in output: $output"
    }
    puts "ok"
    return $output
}
