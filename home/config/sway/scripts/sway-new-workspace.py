#!/usr/bin/env python

import signal
from i3ipc import Connection, Event


primed = False
def prime(_, __):
    global primed
    primed = True


# Open a non-floating window in a new workspace by default
def on_window_open(i3, e):
    global primed

    root = i3.get_tree()
    cid = e.container.id
    con = root.find_by_id(cid)

    if con.parent.layout == 'stacked' or con.parent.layout == 'tabbed':
        return

    if con in con.parent.floating_nodes:
        return

    if primed:
        primed = False
        return
    
    if len(con.parent.nodes) == 1:
        return
    
    ws = max(ws.num for ws in i3.get_workspaces()) + 1

    i3.command(f"move container to workspace {ws}")
    i3.command(f"workspace {ws}")

# Close workspace when closing its last window
def on_window_close(i3, e):
    root = i3.get_tree()
    curr_ws = root.find_focused().workspace()

    if len(curr_ws.nodes) == 0 and len(curr_ws.floating_nodes) == 0:
        i3.command('workspace next_on_output')


signal.signal(signal.SIGUSR1, prime)

i3 = Connection()
i3.on(Event.WINDOW_NEW, on_window_open)
i3.on(Event.WINDOW_CLOSE, on_window_close)

i3.main()

