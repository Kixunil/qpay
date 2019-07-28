// Please see the disclaimer in content_script.js
class WebLNProvider {
	constructor() {
		this.enabled = false;
	}

	enable() {
		return new Promise(function(resolve, reject) {
			resolve();
		})
	}

	getInfo() {
		throw new Error("Unimplemented");
	}

	sendPayment(paymentRequest) {
		return new Promise(function(resolve, reject) {
			var request = new XMLHttpRequest();
			request.onreadystatechange = function() {
				if(this.readyState == 4) {
					if(this.status == 200) {
						if(this.responseText.length > 0) {
							resolve(this.responseText);
						} else {
							reject()
						}
					} else {
						reject()
					}
				}
			};
			request.open("GET", "http://127.0.0.1:9876/" + paymentRequest);
			request.send();
		});
	}

	makeInvoice() {
		throw new Error("Unimplemented");
	}

	signMessage() {
		throw new Error("Unimplemented");
	}

	verifyMessage() {
		throw new Error("Unimplemented");
	}
}

if(document.currentScript) {
	window.webln = new WebLNProvider();
} else {
	console.warn("Failed to inject provider, missing extension id");
}
