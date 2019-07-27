#!/usr/bin/python3

import requests
import time
import json
import sys
import gi
import binascii

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gio, GObject

class LndHttpCommunicator:
    def __init__(self, url, macaroon):
        self._url = url
        self._macaroon = macaroon

    def decode_invoice(self, invoice):
        req = requests.get("https://%s/v1/payreq/%s" % (url, invoice), headers=headers)

        decoded = req.json()

        if "destination" not in decoded:
            return {}
        else:
            return {
                    "destination": decoded["destination"],
                    "num_satoshis": decoded["num_satoshis"]
            }

    def pay_invoice(self, invoice):
        headers = { "Grpc-Metadata-macaroon": self._macaroon }
        req = requests.post("https://%s/v1/channels/transactions?payment_request=" % self._url, headers=headers, json={"payment_request": data["payreq"]})

        return req.json()

class EclairCommunicator:
    def __init__(self, password, port = 8080):
        self._password = password
        self._port = port

    def decode_invoice(self, invoice):
        resp = self._query("parseinvoice", { "invoice": invoice })
        if resp.status_code != 200:
            return { "status": "invalid" }

        decoded = resp.json()

        # Round up satoshis to be on the safe side
        return {
                "destination": decoded["nodeId"],
                "num_satoshis": (decoded["amount"] + 999) / 1000
        }

    def _query(self, command, data = {}):
        url = "http://127.0.0.1:%d/%s" % (self._port, command)
        resp = requests.post(url, data=data, auth=("eclair", self._password))
        return resp

    def pay_invoice(self, invoice):
        resp = self._query("payinvoice", data = { "invoice": invoice })
        if resp.status_code != 200:
            msg = "Failed to execute payinvoice, status: " % resp.status_code
            return {"error": msg }

        payment_id = resp.json()

        time.sleep(0.5)

        while True:
            resp = self._query("getsentinfo", data = { "id": payment_id })
            if resp.status_code != 200:
                msg = "Failed to execute getsentinfo, status: " % resp.status_code
                return {"error": msg }

            resp = resp.json()
            if resp[0]["status"] == "SUCCEEDED":
                return { "payment_preimage": resp[0]["preimage"]}

            if resp[0]["status"] == "FAILED":
                return {"error": "Payment failed" }

            time.sleep(0.5)


config_file = open("/usr/local/etc/qpay/qpay.conf", "r")
config = json.loads(config_file.read())

if config["backend"] == "lnd-http":
    macaroon_file = open("/usr/local/etc/qpay/admin.macaroon", "rb")
    macaroon_binary = macaroon_file.read()
    macaroon = binascii.hexlify(macaroon_binary)

    backend = LndHttpCommunicator(url = config["url"], macaroon = macaroon)

elif config["backend"] == "eclair":
    backend = EclairCommunicator(password = config["password"])

else:
    print("Unknown backend")
    exit(1)

def load_invoice(job, cancellable, data):
    result = None

    if "payreq" not in data:
        data["payreq"] = sys.stdin.readline().rstrip()
    
    if "decoded_req" not in data:
        data["decoded_req"] = backend.decode_invoice(invoice = data["payreq"])

    if "destination" not in data["decoded_req"]:
        result = {"status": "invalid"}

    else:
        result = {
                "status": "success",
                "payreq": data["payreq"],
                "decoded_req": data["decoded_req"],
        }

    def finished():
        data["callback"](result)

    GLib.MainLoop().get_context().invoke_full(GLib.PRIORITY_DEFAULT, finished)

def pay_invoice(job, cancellable, data):
    payment = backend.pay_invoice(invoice = data["payreq"])

    def finished():
        data["callback"](payment)

    GLib.MainLoop().get_context().invoke_full(GLib.PRIORITY_DEFAULT, finished)

class AskPaymentWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="Payment request", default_width=600, default_height=200)

        self.buttons = Gtk.Box(spacing=5)

        self.cancel_btn = Gtk.Button(label="Cancel")
        self.cancel_btn.connect("clicked", Gtk.main_quit)
        self.buttons.pack_start(self.cancel_btn, True, True, 0)

        self.pay_btn = Gtk.Button()
        self.buttons.pack_start(self.pay_btn, True, True, 0)

        self.amt = Gtk.Label()
        self.dst = Gtk.Label()

        self.main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.main.pack_start(self.amt, True, True, 0)
        self.main.pack_start(self.dst, True, True, 0)
        self.main.pack_start(self.buttons, True, True, 0)

        self.spinner = Gtk.Spinner()
        self.spinner.start()
        self.add(self.spinner)

        self.connect("key-press-event", self.key_press)

    def key_press(self, widget, event):
        # Esc
        if event.keyval == 65307:
            Gtk.main_quit()

    def payment_loaded(self, result):
        self.payment_data = result
        if result["status"] == "success":
            self.amt.set_label("Pay %s sats to" % result["decoded_req"]["num_satoshis"])
            self.dst.set_label(result["decoded_req"]["destination"] + " ?")

            self.btn_handle = self.pay_btn.connect("clicked", self.pay_invoice)
            self.pay_btn.set_sensitive(False)
            self.secs = 5
            self.pay_btn.set_label("Pay (%d)" % self.secs)
            self.countdown = GLib.timeout_add(1000, self.countdown_fn, None)

        elif result["status"] == "invalid":
            self.amt.set_label("Invalid invoice")
            self.dst.set_label("")
            self.buttons.remove(self.pay_btn)
            self.cancel_btn.set_label("Close")

        else:
            self.amt.set_label("Connection error")
            self.dst.set_label("")
            self.pay_btn.set_label("Retry")
            self.btn_handle = self.pay_btn.connect("clicked", self.retry)

        self.remove(self.spinner)
        self.add(self.main)
        self.show_all()

    def countdown_fn(self, ignored):
        self.secs -= 1
        if self.secs == 0:
            self.pay_btn.set_label("Pay")
            self.pay_btn.set_sensitive(True)
            GLib.source_remove(self.countdown)
        else:
            self.pay_btn.set_label("Pay (%d)" % self.secs)

        return self.secs > 0

    def pay_invoice(self, widget):
        self.pay_btn.disconnect(self.btn_handle)
        self.remove(self.main)
        self.add(self.spinner)
        def payment_finished(data):
            self.payment_finished(data)

        self.payment_data["callback"] = payment_finished 
        Gio.io_scheduler_push_job(pay_invoice, self.payment_data, GLib.PRIORITY_DEFAULT, None)
        #Gtk.main_quit()

    def retry(self, widget):
        self.pay_btn.disconnect(self.btn_handle)
        self.remove(self.main)
        self.add(self.spinner)
        self.payment_data["callback"] = payment_loaded 
        Gio.io_scheduler_push_job(load_invoice, self.payment_data, GLib.PRIORITY_DEFAULT, None)

    def payment_finished(self, result):
        if "payment_preimage" in result:
            self.amt.set_label("Paid")
            self.dst.set_label("Payment preimage: " + result["payment_preimage"])
            self.buttons.remove(self.pay_btn)
            self.cancel_btn.set_label("Close")
            # Inform the client about success
            print(result["payment_preimage"])

        else:
            self.amt.set_label("Payment failed")
            self.pay_btn.set_label("Retry")
            self.btn_handle = self.pay_btn.connect("clicked", self.pay_invoice)

            if "error" in result:
                self.dst.set_label("Error: " + result["error"])

        self.remove(self.spinner)
        self.add(self.main)
        self.show_all()

GObject.threads_init()

win = AskPaymentWindow()
win.connect("destroy", Gtk.main_quit)

def payment_loaded(result):
    win.payment_loaded(result)

Gio.io_scheduler_push_job(load_invoice, { "callback": payment_loaded }, GLib.PRIORITY_DEFAULT, None)

win.show_all()
Gtk.main()

