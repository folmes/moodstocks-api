package com.moodstocks.android.http;

import java.io.IOException;

import org.apache.http.HttpException;
import org.apache.http.HttpResponse;
import org.apache.http.HttpResponseInterceptor;
import org.apache.http.auth.AuthScheme;
import org.apache.http.auth.AuthState;
import org.apache.http.client.protocol.ClientContext;
import org.apache.http.impl.auth.DigestScheme;
import org.apache.http.protocol.HttpContext;

/*
 * Post-request hook used to cache an auth scheme for later re-use
 * e.g. cache Digest Authentication scheme
 * 
 * See also PreemptiveAuth for more details
 * 
 * Adapted from httpcomponents/httpclient 4.0.1
 * ClientPreemptiveDigestAuthentication.java example
 */
public class PersistentDigest implements HttpResponseInterceptor {

	public void process(final HttpResponse response, final HttpContext context)
			throws HttpException, IOException {
		AuthState authState = (AuthState) context
				.getAttribute(ClientContext.TARGET_AUTH_STATE);
		if (authState != null) {
			AuthScheme authScheme = authState.getAuthScheme();
			// Stick the auth scheme to the local context, so
			// we could try to authenticate subsequent requests
			// preemptively
			if (authScheme instanceof DigestScheme) {
				context.setAttribute("preemptive-auth", authScheme);
			}
		}
	}
}
