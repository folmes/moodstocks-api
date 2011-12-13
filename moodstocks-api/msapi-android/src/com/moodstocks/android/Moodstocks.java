package com.moodstocks.android;

import android.content.Context;

import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.HttpProtocolParams;

import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.ByteArrayBody;
import org.apache.http.entity.mime.content.ContentBody;
import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.AsyncHttpResponseHandler;
import com.moodstocks.android.http.PreemptiveAuth;
import com.moodstocks.android.http.PersistentDigest;

final class Moodstocks {

	private static final String MS_USER_AGENT = "msapi-android";
	private static final String MS_HOST = "api.moodstocks.com";
	private static final String MS_API_VERSION = "/v2";

	private static Moodstocks ms;

	private final Context mContext;
	private final AsyncHttpClient mClient;

	public static void init(Context context) {
		if (ms == null) {
			ms = new Moodstocks(context);
		}
	}

	public static Moodstocks shared() {
		return ms;
	}

	public void setCredentials(String key, String secret) {
		DefaultHttpClient httpclient = (DefaultHttpClient) mClient.getHttpClient();
		httpclient.getCredentialsProvider().setCredentials(
				new AuthScope(MS_HOST, 80),
				new UsernamePasswordCredentials(key, secret));
	}

	public void echo(AsyncHttpResponseHandler responseHandler) {
		mClient.post(mContext, "http://" + MS_HOST + MS_API_VERSION + "/echo",
				null, responseHandler);
	}

	public void search(byte[] query, AsyncHttpResponseHandler responseHandler) {
		// NOTE: we can't use this method since the internal
		// `SimpleMultipartEntity' is not
		// repeatable, i.e. it cannot be read multiple times as it is required
		// when
		// the request has to be retried (e.g. for 401/200 cycle)
		// Let's use the Http Components Mime `MultipartEntity' class instead
		/* RequestParams params = new RequestParams(); params.put("image_file", new
		 * ByteArrayInputStream(query), "image_file"); mClient.post("http://" +
		 * MS_HOST + MS_API_VERSION + "/search", params, responseHandler); */

		ContentBody body = new ByteArrayBody(query, "image_file");
		MultipartEntity multipartContent = new MultipartEntity();
		multipartContent.addPart("image_file", body);
		mClient.post(mContext, "http://" + MS_HOST + MS_API_VERSION + "/search",
				multipartContent, null, responseHandler);
	}

	public void cancelRequests() {
		mClient.cancelRequests(mContext, true);
	}

	private Moodstocks(Context context) {
		mContext = context;
		mClient = new AsyncHttpClient();
		DefaultHttpClient httpclient = (DefaultHttpClient) mClient.getHttpClient();

		// Set a custom UserAgent
		HttpProtocolParams.setUserAgent(httpclient.getParams(), MS_USER_AGENT);

		// This is a work around since AuthCache (which implements a similar
		// thing) is not available within the Http Components library bundled
		// with
		// Android see PreemptiveAuth and PersistentDigest for more details
		httpclient.addRequestInterceptor(new PreemptiveAuth(), 0);
		httpclient.addResponseInterceptor(new PersistentDigest());
	}
}
