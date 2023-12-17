import sys
import win32gui
import win32con
import time

UPDATE_INTERVAL = 0.0625

if len(sys.argv) < 2:
	print("no windows provided")
	raise SystemExit

trgt_hwnd = win32gui.FindWindow(None, sys.argv[1])#input())#sys.argv[1])
adjw_hwnd = win32gui.FindWindow(None, sys.argv[2])#input())#sys.argv[2])

try:
	styles = win32gui.GetWindowLong(adjw_hwnd, win32con.GWL_EXSTYLE)
	styles = win32con.WS_EX_LAYERED | win32con.WS_EX_TRANSPARENT
	win32gui.SetWindowLong(adjw_hwnd, win32con.GWL_EXSTYLE, styles)
	win32gui.SetLayeredWindowAttributes(adjw_hwnd, 0, 255, win32con.LWA_ALPHA)
	while True:
		if win32gui.IsWindow(trgt_hwnd) and win32gui.IsWindow(adjw_hwnd):
			rect = win32gui.GetWindowRect(trgt_hwnd)
			x = rect[0] + 8
			y = rect[1] + 31
			w = rect[2] - x - 8
			h = rect[3] - y - 8
			win32gui.MoveWindow(adjw_hwnd, x,y, w,h, True)
			adjw_hwnd = win32gui.FindWindow(None, sys.argv[2])#input())#sys.argv[2])
			time.sleep(UPDATE_INTERVAL) 
		else:
			print("missing windows tgt:",win32gui.IsWindow(trgt_hwnd),"ovr:",win32gui.IsWindow(adjw_hwnd))
			break
except KeyboardInterrupt:
	raise SystemExit
