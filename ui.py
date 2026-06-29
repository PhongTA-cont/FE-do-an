import tkinter as tk
from tkinter import filedialog, messagebox
import glob
import os
import getopt
import sys
from random import randint
from datetime import datetime
import threading
import logging as log

import can
import serial
import serial.tools.list_ports

# =========================================================================
# LỚP MẶT NẠ BYPASS PYTHON-CAN (Giao tiếp trực tiếp bằng Pyserial)
# =========================================================================
class SimpleSerialCAN:
	def __init__(self, port, baudrate):
		self.ser = serial.Serial(port, baudrate, timeout=0.1)
		self.ser.reset_input_buffer()
		self.ser.reset_output_buffer()

	def recv(self, timeout=None):
		try:
			line = self.ser.read_until(b'\r')
			if not line:
				return None
			
			line = line.decode('ascii', errors='ignore').strip()
			
			# 1. Hỗ trợ format "7DF#02010D0000000000" do App gửi lên
			if '#' in line:
				parts = line.split('#')
				if len(parts) == 2:
					arb_id = int(parts[0], 16)
					data_hex = parts[1]
					# Tách chuỗi hex thành mảng byte
					data_bytes = [int(data_hex[i:i+2], 16) for i in range(0, len(data_hex), 2)]
					
					return can.Message(
						arbitration_id=arb_id,
						data=data_bytes,
						is_extended_id=False
					)
					
			# 2. Vẫn giữ lại format chuẩn Lawicel cũ (phòng hờ bạn dùng terminal khác để test)
			elif line.startswith('t') and len(line) >= 5:
				arb_id = int(line[1:4], 16)
				dlc = int(line[4:5], 16)
				data_bytes = []
				for i in range(dlc):
					byte_hex = line[5 + i*2 : 7 + i*2]
					if byte_hex:
						data_bytes.append(int(byte_hex, 16))
				
				return can.Message(
					arbitration_id=arb_id,
					data=data_bytes,
					is_extended_id=False
				)
		except Exception:
			pass
		return None

	def send(self, msg):
		# Đóng gói dữ liệu trả về đúng format "7E8#03410D32\r\n" mà màn hình OBD Dashboard đang đợi
		data_hex = ''.join('{:02X}'.format(b) for b in msg.data)
		out = '{:03X}#{}\r\n'.format(msg.arbitration_id, data_hex)
		try:
			self.ser.write(out.encode('ascii'))
		except:
			pass

	def shutdown(self):
		self.ser.close()

# =========================================================================

class Application(tk.Frame):
	def __init__(self, master=None):
		super().__init__(master)
		self.master = master
		self.master.minsize(width=800, height=600)
		master.protocol("WM_DELETE_WINDOW", self.close_app)
		tk.Grid.rowconfigure(master, 0, weight=1)
		tk.Grid.columnconfigure(master, 0, weight=1)

		self.event = threading.Event()
		self.bus = None
		self.can_is_started = False

		self.can_device_var = tk.StringVar()
		# Gán sẵn giá trị mặc định để bấm Auto là chạy ngay
		self.speed_var = tk.IntVar(value=40)
		self.speed_var_auto = tk.BooleanVar()
		self.speed_var_min = tk.IntVar(value=20)
		self.speed_var_max = tk.IntVar(value=80)
		
		self.rpm_var = tk.DoubleVar(value=800)
		self.rpm_var_auto = tk.BooleanVar()
		self.rpm_var_min = tk.DoubleVar(value=1000)
		self.rpm_var_max = tk.DoubleVar(value=3000)

		self.create_controls()

	def close_app(self):
		if self.can_is_started:
			self.can_disconnect()
		self.master.destroy()

	def get_can_devices(self):
		ports = serial.tools.list_ports.comports()
		devices = [port.device for port in ports]
		if not devices:
			devices = ['COM1']
		return devices

	def create_controls(self):
		frame=tk.Frame(self.master)
		frame.grid(row=0, column=0, sticky=tk.N+tk.S+tk.E+tk.W)

		frame.columnconfigure(1, weight=1)
		frame.columnconfigure(4, weight=1)
		frame.columnconfigure(5, weight=1)

		row_id = 0

		can_frame = tk.LabelFrame(frame, text="Interface")
		can_frame.grid(row=row_id, column=0, padx=(10, 10), sticky=tk.W+tk.W+tk.N+tk.S)

		devices = self.get_can_devices()
		if len(devices) > 0:
			self.can_device_var.set(devices[0])
		else:
			devices.append('')

		self.can_options = tk.OptionMenu(can_frame, self.can_device_var, *devices)
		self.can_options.grid(row=0, column=0, pady=(5, 10), sticky=tk.W+tk.E)

		btn_refresh = tk.Button(can_frame, text="R", command=self.refresh_list)
		btn_refresh.grid(row=0, column=1, pady=(5, 10), sticky=tk.E)

		self.connect = tk.Button(can_frame, text="Connect", command=self.can_connect)
		self.connect.grid(row=1, column=0, sticky=tk.W+tk.E)

		self.disconnect = tk.Button(can_frame, text="Disconnect", state="disabled", command=self.can_disconnect)
		self.disconnect.grid(row=2, column=0, sticky=tk.W+tk.E)

		row_id += 1

		self.lbl_speed = tk.Label(frame, text="Speed, km/h")
		self.lbl_speed.grid(row=row_id, column=0, padx=(10, 10), sticky=tk.W)

		self.sc_speed = tk.Scale(frame, from_=0, to=255, orient=tk.HORIZONTAL, variable=self.speed_var)
		self.sc_speed.grid(row=row_id, column=1, padx=(5, 5), sticky=tk.W+tk.E)

		self.cb_speed_auto = tk.Checkbutton(frame, text="Auto mode", variable=self.speed_var_auto, command=self.on_cb_speed_auto)
		self.cb_speed_auto.grid(row=row_id, column=3)

		self.sc_speed_min = tk.Scale(frame, from_=0, to=254, orient=tk.HORIZONTAL, label="Min", state="disabled", variable=self.speed_var_min, command=self.on_sc_speed)
		self.sc_speed_min.grid(row=row_id, column=4, padx=(5, 5), sticky=tk.W+tk.E)

		self.sc_speed_max = tk.Scale(frame, from_=1, to=255, orient=tk.HORIZONTAL, label="Max", state="disabled", variable=self.speed_var_max, command=self.on_sc_speed)
		self.sc_speed_max.grid(row=row_id, column=5, padx=(5, 10), sticky=tk.W+tk.E)

		row_id += 1

		self.lbl_rpm = tk.Label(frame, text="RPM, km/h")
		self.lbl_rpm.grid(row=row_id, column=0, padx=(10, 10), sticky=tk.W)

		self.sc_rpm = tk.Scale(frame, from_=0, to=16383.75, orient=tk.HORIZONTAL, resolution=0.25, variable=self.rpm_var)
		self.sc_rpm.grid(row=row_id, column=1, padx=(5, 5), sticky=tk.W+tk.E)

		self.cb_rpm_auto = tk.Checkbutton(frame, text="Auto mode", variable=self.rpm_var_auto, command=self.on_cb_rpm_auto)
		self.cb_rpm_auto.grid(row=row_id, column=3)

		self.sc_rpm_min = tk.Scale(frame, from_=0, to=16383.75, orient=tk.HORIZONTAL, label="Min", resolution=0.25, state="disabled", variable=self.rpm_var_min, command=self.on_sc_rpm)
		self.sc_rpm_min.grid(row=row_id, column=4, padx=(5, 5), sticky=tk.W+tk.E)

		self.sc_rpm_max = tk.Scale(frame, from_=1, to=16383.75, orient=tk.HORIZONTAL, label="Max", resolution=0.25, state="disabled", variable=self.rpm_var_max, command=self.on_sc_rpm)
		self.sc_rpm_max.grid(row=row_id, column=5, padx=(5, 10), sticky=tk.W+tk.E)

		row_id += 1

		tk.Grid.rowconfigure(frame, row_id, weight=1)

		log_frame = tk.Frame(frame)
		log_frame.grid(row=row_id, column=0, columnspan=6, padx=(10, 10), pady=(10, 10), sticky=tk.W+tk.E+tk.N+tk.S)
		log_frame.columnconfigure(0, weight=1)
		log_frame.rowconfigure(0, weight=1)

		scrollbar = tk.Scrollbar(log_frame)
		scrollbar.grid(row=0, column=1, sticky=tk.E+tk.N+tk.S)

		self.logbox = tk.Text(log_frame, background="black", foreground="medium spring green", font="Mono 10", yscrollcommand=scrollbar.set)
		self.logbox.configure(state='normal')
		self.logbox.insert(tk.END, "Select interface and press 'Connect' button.\n")
		self.logbox.configure(state='disabled')
		self.logbox.grid(row=0, column=0, sticky=tk.W+tk.E+tk.N+tk.S)

		scrollbar.config(command=self.logbox.yview)

		row_id += 1

		buttons_frame = tk.Frame(frame)
		buttons_frame.grid(row=row_id, column=0, columnspan=6, sticky=tk.E+tk.S)

		btn_clearlog = tk.Button(buttons_frame, text="Clear log", command=self.clear_log)
		btn_clearlog.grid(row=row_id, column=0, padx=(10, 5), pady=(10, 10))

		btn_savelog = tk.Button(buttons_frame, text="Save log", command=self.save_log)
		btn_savelog.grid(row=row_id, column=1, padx=(10, 5), pady=(10, 10))

		btn_quit = tk.Button(buttons_frame, text="Quit", command=self.close_app)
		btn_quit.grid(row=row_id, column=2, padx=(5, 10), pady=(10, 10))

	def refresh_list(self):
		devices = self.get_can_devices()
		menu = self.can_options['menu']
		menu.delete(0, tk.END)
		self.can_device_var.set('')
		for device in devices:
			menu.add_command(label=device, command=lambda value=device: self.can_device_var.set(value))
		if len(devices) > 0:
			self.can_device_var.set(devices[0])

	def can_disconnect(self):
		self.can_is_started = False
		self.bus.shutdown()
		self.h_receiver.join(timeout=2)

		self.can_options['state'] = 'normal'
		self.connect['state'] = 'normal'
		self.disconnect['state'] = 'disabled'

		self.event.clear()
		self.add_log('Bus {:s} is disconnected'.format(self.can_device_var.get()))

	def can_connect(self):
		if self.can_device_var.get() == '':
			messagebox.showwarning(message="CAN interface is not available or selected")
			return

		try:
			# Gọi lớp MẶT NẠ thay vì thư viện can.interface.Bus()
			self.bus = SimpleSerialCAN(self.can_device_var.get(), 115200)
		except Exception as e:
			self.bus = None
			self.add_log(f"Connection Error: {e}")

		if self.bus is None:
			self.add_log('Bus {:s} cannot be connected'.format(self.can_device_var.get()))
			return

		self.h_receiver = threading.Thread(target=self.receive_all)
		self.h_receiver.start()

		self.can_is_started = True
		self.disconnect['state'] = 'normal'
		self.connect['state'] = 'disabled'
		self.can_options['state'] = 'disabled'

		self.event.set()
		self.add_log('Bus {:s} is connected (Bypass Mode - 115200)'.format(self.can_device_var.get()))

	def add_log(self, message):
		# Tạo một hàm phụ để cập nhật UI
		def _update_gui():
			self.logbox.configure(state='normal')
			mpt = '{:%Y.%m.%d-%H:%M:%S.%f}: {:s}\n'.format(datetime.utcnow(), message)
			self.logbox.insert(tk.END, mpt)
			self.logbox.configure(state='disabled')
			self.logbox.see(tk.END)
			
		# Uỷ quyền việc cập nhật an toàn cho Main Thread
		self.master.after(0, _update_gui)
	def clear_log(self):
		self.logbox.configure(state='normal')
		self.logbox.delete(1.0, tk.END)
		self.logbox.configure(state='disabled')

	def save_log(self):
		files = [('Logs', '*.log'), ('All Files', "*.*"), ('Text files', '*.txt')]
		file_handler = filedialog.asksaveasfile(title = "Save log", defaultextension=".log", filetypes=files)
		if file_handler is None: return
		file_handler.write(str(self.logbox.get(1.0, tk.END)))
		file_handler.close()

	def on_sc_speed(self, val):
		if self.speed_var_min.get() > self.speed_var_max.get():
			self.speed_var_max.set(self.speed_var_min.get() + 1)

	def on_cb_speed_auto(self):
		if self.speed_var_auto.get() != True:
			self.sc_speed_min['state'] = "disabled"
			self.sc_speed_max['state'] = "disabled"
			self.sc_speed['state'] = "normal"
		else:
			self.sc_speed_min['state'] = "normal"
			self.sc_speed_max['state'] = "normal"
			self.sc_speed['state'] = "disabled"

	def on_sc_rpm(self, val):
		if self.rpm_var_min.get() > self.rpm_var_max.get():
			self.rpm_var_max.set(self.rpm_var_min.get() + 1)

	def on_cb_rpm_auto(self):
		if self.rpm_var_auto.get() != True:
			self.sc_rpm_min['state'] = "disabled"
			self.sc_rpm_max['state'] = "disabled"
			self.sc_rpm['state'] = "normal"
		else:
			self.sc_rpm_min['state'] = "normal"
			self.sc_rpm_max['state'] = "normal"
			self.sc_rpm['state'] = "disabled"

	def service1(self, msg):
		pid = msg.data[2]
		self.add_log('>> Yêu cầu Service 1, PID=0x{:02x}'.format(pid))
		# ==========================================
		# BƯỚC 1: ĐỌC THAM SỐ GỐC TỪ GIAO DIỆN BE
		# ==========================================
		min_rpm, max_rpm = int(self.rpm_var_min.get()), int(self.rpm_var_max.get())
		if min_rpm > max_rpm: min_rpm, max_rpm = max_rpm, min_rpm
		current_rpm = randint(min_rpm, max_rpm) if self.rpm_var_auto.get() else self.rpm_var.get()
		
		min_speed, max_speed = int(self.speed_var_min.get()), int(self.speed_var_max.get())
		if min_speed > max_speed: min_speed, max_speed = max_speed, min_speed
		current_speed = randint(min_speed, max_speed) if self.speed_var_auto.get() else self.speed_var.get()

		# ==========================================
		# BƯỚC 2: TÍNH TOÁN CÁC BIẾN VẬT LÝ VỆ TINH
		# (Tất cả đều biến thiên bám theo RPM và Speed)
		# ==========================================
		# 1. Engine Load (Tải động cơ: 0-100%). Giả sử xe max 6000 rpm
		load_pct = min(100.0, (current_rpm / 6000.0) * 100.0)
		
		# 2. Coolant Temp (Nước làm mát: -40 đến 215C). Mặc định 85C, vòng tua cao thì nóng hơn.
		coolant_temp = min(215.0, 85.0 + (current_rpm / 1000.0) * 2.0)
		
		# 3. Intake MAP (Áp suất cổ hút: 0-255 kPa). Tỉ lệ theo tải động cơ.
		map_kpa = 30.0 + (load_pct / 100.0) * 70.0
		
		# 4. Intake Air Temp (Nhiệt độ khí nạp). Thường ổn định quanh 40C.
		iat_temp = 40.0
		
		# 5. MAF (Lượng gió nạp: 0-655 g/s). Tỉ lệ thuận với RPM.
		maf_gs = current_rpm / 150.0
		
		# 6. Throttle (Bướm ga: 0-100%). Bám sát theo tải động cơ.
		throttle_pct = min(100.0, load_pct * 0.9)
		
		# 7. Barometric (Áp suất khí quyển). Cố định ở mực nước biển là 100 kPa.
		baro_kpa = 100.0

		# ==========================================
		# BƯỚC 3: ĐẢO NGƯỢC CÔNG THỨC SAE J1979 ĐỂ ĐÓNG BYTE
		# ==========================================
		if pid == 0x00:
			# Khai báo các PID được hỗ trợ (Từ 01 đến 20)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x06, 0x41, 0x00, 0x18, 0x3B, 0x80, 0x00], is_extended_id=False))
            
		elif pid == 0x04:
			# Engine Load | Công thức FE: A * 100 / 255 
			A = int((load_pct * 255.0) / 100.0)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x03, 0x41, 0x04, A], is_extended_id=False))

		elif pid == 0x05:
			# Coolant Temp | Công thức FE: A - 40
			A = int(coolant_temp + 40.0)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x03, 0x41, 0x05, A], is_extended_id=False))
			
		elif pid == 0x0B:
			# Intake MAP | Công thức FE: A
			A = int(map_kpa)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x03, 0x41, 0x0B, A], is_extended_id=False))

		elif pid == 0x0C:
			# RPM | Công thức FE: (256A + B) / 4
			val = int(current_rpm * 4)
			A = val // 256
			B = val % 256
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x04, 0x41, 0x0C, A, B], is_extended_id=False))
            
		elif pid == 0x0D:
			# Speed | Công thức FE: A
			A = int(current_speed)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x03, 0x41, 0x0D, A], is_extended_id=False))
			
		elif pid == 0x0F:
			# Intake Air Temp | Công thức FE: A - 40
			A = int(iat_temp + 40.0)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x03, 0x41, 0x0F, A], is_extended_id=False))
			
		elif pid == 0x10:
			# MAF | Công thức FE: (256A + B) / 100
			val = int(maf_gs * 100)
			A = val // 256
			B = val % 256
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x04, 0x41, 0x10, A, B], is_extended_id=False))
			
		elif pid == 0x11:
			# Throttle Position | Công thức FE: A * 100 / 255
			A = int((throttle_pct * 255.0) / 100.0)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x03, 0x41, 0x11, A], is_extended_id=False))
			
		elif pid == 0x33:
			# Barometric Pressure | Công thức FE: A
			A = int(baro_kpa)
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x03, 0x41, 0x33, A], is_extended_id=False))
			
		else:
			self.add_log('Service 1, unknown PID=0x{:02x}'.format(pid))

	def service9(self, msg):
		if msg.data[2] == 0x02:
			# Trả về 3 khung frame để ghép thành mã số VIN
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x10, 0x14, 0x49, 0x02, 0x01, 0x33, 0x46, 0x41], is_extended_id=False))
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x21, 0x44, 0x50, 0x34, 0x46, 0x4A, 0x32, 0x42], is_extended_id=False))
			self.bus.send(can.Message(arbitration_id=0x7e8, data=[0x22, 0x4D, 0x31, 0x31, 0x33, 0x39, 0x31, 0x33], is_extended_id=False))
			self.add_log(">> Sent VIN (Multi-frame)")

	def receive_all(self):
		self.event.wait()
		while self.can_is_started:
			msg = self.bus.recv(timeout=0.1)
			if msg is None: continue

			if msg.arbitration_id != 0x7df:
				continue

			service = msg.data[1]
			# Phân loại lệnh gửi từ App để gọi đúng service
			if service == 0x01:
				self.service1(msg)
			elif service == 0x09:
				self.service9(msg)
			else:
				self.add_log('Service 0x{:02x} is not supported'.format(service))

	# def receive_all(self):
	# 	self.event.wait()
	# 	while self.can_is_started:
	# 		msg = self.bus.recv(timeout=0.1)
	# 		if msg is None: continue

	# 		if msg.arbitration_id != 0x7df:
	# 			self.add_log('Unknown Id 0x{:03x}'.format(msg.arbitration_id))
	# 			continue

	# 		if msg.data[1] == 0x01:
	# 			self.service1(msg)
	# 		else:
	# 			self.add_log('Service {:d} is not supported'.format(msg.data[1]))

if __name__ == "__main__":
	log.basicConfig(level=log.INFO)
	window = tk.Tk()
	window.title("ECU Simulator - Bypass Serial Mode")
	app = Application(master=window)
	app.mainloop()