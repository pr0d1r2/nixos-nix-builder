proc expect_services_then_milestone {service_dict milestone_re {timeout_s 180}} {
    set pending [dict create]
    dict for {svc _} $service_dict {
        dict set pending $svc 1
    }

    set timeout $timeout_s
    set seen 0
    set total [dict size $pending]

    while {[dict size $pending] > 0} {
        expect {
            -re $milestone_re {
                set clean [regsub -all {\x1b\[[0-9;]*m} $expect_out(0,string) {}]
                puts "\[OK\]   Milestone: $clean"
                return
            }
            -re {\[FAILED\]} {
                puts "\[WARN\] $expect_out(0,string)"
            }
            "\n" {
                set line $expect_out(buffer)
                set clean [regsub -all {\x1b\[[0-9;]*m} $line {}]
                dict for {svc _} $pending {
                    if {[string match "*$svc*" $clean]} {
                        dict unset pending $svc
                        incr seen
                        puts "\[OK\]   Service ($seen/$total): $svc"
                        break
                    }
                }
            }
            timeout {
                set missing {}
                dict for {svc _} $pending {
                    lappend missing $svc
                }
                bail "Timed out after ${timeout_s}s. Missing services: [join $missing {, }]"
            }
            eof {
                bail "Process exited before reaching milestone"
            }
        }
    }

    expect {
        -re $milestone_re {
            set clean [regsub -all {\x1b\[[0-9;]*m} $expect_out(0,string) {}]
            puts "\[OK\]   Milestone: $clean"
        }
        eof {
            bail "Process exited before milestone (connection lost?)"
        }
        timeout {
            bail "All services started but milestone not reached after ${timeout_s}s"
        }
    }
}
