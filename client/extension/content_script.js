// Largely inspired by Joule, some code copied
// 
// If you do find something stupid here, please consider this: I'm not JS
// developer and I hate JS and web dev. I did it only out of neccessity.
//
// Also, while I like the idea of typescript, I decided against it to not
// delay development by myself learning it also to not bring in dependencies
// that may increase attack surface and finally because npm is needed for it to
// install and I had some horrible experiences with npm.
//
// If you don't like something, please make a pull request with an explanation
// of why it should be changed.


// Checks the doctype of the current document if it exists
function doctypeCheck () {
  const doctype = window.document.doctype;
  if (doctype) {
    return doctype.name === 'html';
  } else {
    return true;
  }
}

// Returns whether or not the extension (suffix) of the current document is prohibited
function suffixCheck () {
  const prohibitedTypes = [
    /\.xml$/,
    /\.pdf$/,
  ];
  const currentUrl = window.location.pathname;
  for (const type of prohibitedTypes) {
    if (type.test(currentUrl)) {
      return false;
    }
  }
  return true;
}

// Checks the documentElement of the current document
function documentElementCheck () {
  const docNode = document.documentElement.nodeName;
  if (docNode) {
    return docNode.toLowerCase() === 'html';
  }
  return true;
}

function shouldInject() {
	 return doctypeCheck() && suffixCheck() && documentElementCheck();
}

function injectScript() {
	try {
		if(!document) throw new Error("No document");
		if(!document.body) throw new Error("No container element");
		const scriptEl = document.createElement("script");
		scriptEl.setAttribute("type", "text/javascript");
		scriptEl.setAttribute("src", browser.extension.getURL("inpage_script.js"));
		document.body.appendChild(scriptEl)
	} catch(err) {
		console.error("Failed to inject qpay", err)
	}
}

if(shouldInject()) {
	injectScript();
}

if(document && document.body) {
	document.body.addEventListener("click", function(ev) {
		const target = ev.target;
		if(!target || !target.closest) {
			return;
		}

		const link = target.closest('[href^="lightning:"]');
		if(link) {
			const href = link.getAttribute("href");
			const paymentRequest = href.replace("lightning:", "");
			req = new XMLHttpRequest();
			req.open("GET", "http://127.0.0.1:9876/" + paymentRequest);
			req.send();
			ev.preventDefault();
		}
	});
}
