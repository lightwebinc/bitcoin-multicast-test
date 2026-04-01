#!/usr/bin/env bash
# Start a tmux session with one window per receiver running tcpdump on enp6s0.
# Run this on the lax host: bash ~/bitcoin-multicast-test-lax/tmux-recv.sh

SESSION="mcast-recv"

tmux new-session -d -s "$SESSION" -n recv1 \
  "echo '==> recv1: lxc exec recv1 -- tcpdump -i enp6s0 -n ip6 and udp'; echo ''; lxc exec recv1 -- tcpdump -i enp6s0 -n 'ip6 and udp'; read"

tmux new-window -t "$SESSION" -n recv2 \
  "echo '==> recv2: lxc exec recv2 -- tcpdump -i enp6s0 -n ip6 and udp'; echo ''; lxc exec recv2 -- tcpdump -i enp6s0 -n 'ip6 and udp'; read"

tmux new-window -t "$SESSION" -n recv3 \
  "echo '==> recv3: lxc exec recv3 -- tcpdump -i enp6s0 -n ip6 and udp'; echo ''; lxc exec recv3 -- tcpdump -i enp6s0 -n 'ip6 and udp'; read"

tmux select-window -t "$SESSION:recv1"
tmux attach-session -t "$SESSION"
