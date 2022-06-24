#!/usr/bin/env python

import logging
import sys
import signal

from i3ipc.aio import Connection
from i3ipc import Event

import asyncio


DELAY = 1.5
update_task = None


def change_number(ws_dict, num, new_num):
    if new_num != num and new_num in ws_dict:
        raise ValueError("New nuber is not free")

    name = ws_dict[num]
    parts = name.split(':')
    logging.info(f'renumbering {num} {name} to {new_num}')
    
    try:
        int(parts[0])
        parts[0] = str(new_num)
    except ValueError:
        parts.insert(0, str(new_num))
    new_name = ':'.join(parts)

    del ws_dict[num]
    ws_dict[new_num] = new_name

    cmd = f'rename workspace "{name}" to "{new_name}"'
    logging.info(cmd)
    return cmd


async def set_first(i3, delay):
    logging.info('waiting delay')
    await asyncio.sleep(delay)
    logging.info('Setting workspace first')

    tree = await i3.get_tree()
    name = tree.find_focused().workspace().name
    workspaces = tree.find_focused().workspace().parent.workspaces()
    ws_dict = {ws.num: ws.name for ws in workspaces if ws.num}
    min_num = min(ws_dict.keys())

    try:
        num = int(name.split(':')[0])
        if num == min_num: # already first
            logging.info('already first')
            return 
    except ValueError:
        ws_dict[1000] = name
        await i3.command(change_number(ws_dict, 1000, min_num - 1))
        num = min_num - 1
    
    gap_num = next(i for i in range(1, len(ws_dict) + 1) if i not in ws_dict or i == num)
    
    if min_num > 1:
        await i3.command(change_number(ws_dict, num, 1))
        return

    logging.info('shifting reorder')
    await i3.command(change_number(ws_dict, num, 0))
    for i in range(gap_num, 0, -1):
        await i3.command(change_number(ws_dict, i - 1, i))


def schedule_update(i3, delay):
    global update_task

    if update_task is not None:
        update_task.cancel()

    logging.info(f'scheduling task to move workspace in {delay}')
    update_task = asyncio.create_task(set_first(i3, delay))


async def main():
    i3 = await Connection(auto_reconnect=True).connect()
    loop = asyncio.get_event_loop()
    i3.on(Event.WORKSPACE_FOCUS, lambda i3, _: schedule_update(i3, DELAY))
    loop.add_signal_handler(signal.SIGUSR1, lambda: schedule_update(i3, 0))
    await i3.main()


if __name__ == '__main__':
    if '--debug' in sys.argv:
        logging.basicConfig(level=logging.DEBUG)

    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())

